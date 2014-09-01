# VirtualBox VM support code

# List running VMs

def list_running_vbox_vms()
  vm_list = %x[VBoxManage list runningvms].split("\n")
  puts
  puts "Running VMs:"
  puts
  vm_list.each do |vm_name|
    vm_name = vm_name.split(/"/)[1]
    os_info = %x[VBoxManage showvminfo "#{vm_name}" |grep '^Guest OS' |cut -f2 -d:].chomp.gsub(/^\s+/,"")
    puts vm_name+"\t"+os_info
  end
  puts
  return
end

# Set VirtualBox ESXi options

def configure_vmware_vbox_vm(client_name)
  modify_vbox_vm(client_name,"rtcuseutc","on")
  modify_vbox_vm(client_name,"vtxvpid","on")
  modify_vbox_vm(client_name,"vtxux","on")
  modify_vbox_vm(client_name,"hwvirtex","on")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion","None")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor","Intel Corporation")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct","440BX Desktop Reference Platform")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor","VMware, Inc.")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct","VMware Virtual Platform")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor","Phoenix Technologies LTD")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion","6.0")
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor","No Enclosure")
  vbox_vm_uuid = get_vbox_vm_uuid(client_name)
  vbox_vm_uuid = "VMware-"+vbox_vm_uuid
  setextradata_vbox_vm(client_name,"VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial",vbox_vm_uuid)
  return
end

# Get VirtualBox UUID

def get_vbox_vm_uuid(client_name)
  vbox_vm_uuid = %x[VBoxManage showvminfo "#{client_name}" |grep ^UUID |awk '{print $2}'].chomp
  return vbox_vm_uuid
end

# Set VirtualBox ESXi options

def configure_vmware_esxi_vbox_vm(client_name)
  configure_vmware_esxi_defaults()
  modify_vbox_vm(client_name,"cpus",$default_vm_vcpu)
  configure_vmware_vbox_vm(client_name)
  return
end

# Set VirtualBox vCenter option

def configure_vmware_vcenter_vbox_vm(client_name)
  configure_vmware_vcenter_defaults()
  configure_vmware_vbox_vm(client_name)
  return
end

# Clone VM

def clone_vbox_vm(client_name,new_name,client_mac,client_ip)
  exists = check_vbox_vm_exists(client_name)
  if exists == "no"
    puts "Warning:\tVirtualBox VM "+client_name+" does not exist"
    exit
  end
  %x[VBoxManage clonevm #{client_name} --name #{new_name} --register]
  if client_ip.match(/[0-9]/)
    add_hosts_entry(new_name,client_ip)
  end
  if client_mac.match(/[0-9]|[A-z]/)
    change_vbox_vm_mac(new_name,client_mac)
  end
  return
end

# Export OVA

def export_vbox_ova(client_name,ova_file)
  exists = check_vbox_vm_exists(client_name)
  if exists == "yes"
    stop_vbox_vm(client_name)
    if !ova_file.match(/[A-z]|[0-9]/)
      ova_file = "/tmp/"+client_name+".ova"
      puts "Warning:\tNo ouput file given"
      puts "Information:\tExporting VM "+client_name+" to "+ova_file
    end
    if !ova_file.match(/\.ova$/)
      ova_file = ova_file+".ova"
    end
    %x[VBoxManage export "#{client_name}" -o "#{ova_file}"]
  else
    puts "Warning:\tVirtualBox VM "+client_name+"does not exist"
  end
  return
end

# Import OVA

def import_vbox_ova(client_name,client_mac,client_ip,ova_file)
  exists = check_vbox_vm_exists(client_name)
  if exists == "no"
    exists = check_vbox_vm_config_exists(client_name)
    if exists == "yes"
      delete_vbox_vm_config(client_name)
    end
    if !ova_file.match(/\//)
      ova_file = $iso_base_dir+"/"+ova_file
    end
    if File.exist?(ova_file)
      if client_name.match(/[A-z]|[0-9]/)
        %x[VBoxManage import #{ova_file} --vsys 0 --vmname #{client_name}]
      else
        client_name = %x[VBoxManage import -n #{ova_file} |grep "Suggested VM name"].split(/\n/)[-1]
        if !client_name.match(/[A-z]|[0-9]/)
          puts "Warning:\tCould not determine VM name for Virtual Appliance "+ova_file
          exit
        else
          client_name = client_name.split(/Suggested VM name /)[1].chomp
          %x[VBoxManage import #{ova_file}]
        end
      end
    else
      puts "Warning:\tVirtual Appliance "+ova_file+"does not exist"
    end
  end
  if client_ip.match(/[0-9]/)
    add_hosts_entry(client_name,client_ip)
  end
  vbox_socket_name = add_socket_to_vbox_vm(client_name)
  add_serial_to_vbox_vm(client_name)
  if $default_vm_network.match(/bridged/)
    vbox_nic_name = get_bridged_vbox_nic()
    add_bridged_network_to_vbox_vm(client_name,vbox_nic_name)
  else
    vbox_nic_name = check_vbox_hostonly_network()
    add_nonbridged_network_to_vbox_vm(client_name,vbox_nic_name)
  end
  if !client_mac.match(/[0-9]|[A-z]/)
    client_mac = get_vbox_vm_mac(client_name)
  else
    change_vbox_vm_mac(client_name,client_mac)
  end
  if ova_file.match(/VMware/)
    configure_vmware_vcenter_defaults()
    configure_vmware_vbox_vm(client_name)
  end
  puts "Warning:\tVirtual Appliance "+ova_file+" imported with VM name "+client_name+" and MAC address "+client_mac
  return
end

# List Linux KS VirtualBox VMs

def list_ks_vbox_vms()
  search_string = "rhel|centos|ubuntu"
  list_vbox_vms(search_string)
  return
end

# List Solaris Kickstart VirtualBox VMs

def list_js_vbox_vms()
  search_string = "sol.10"
  list_vbox_vms(search_string)
  return
end

# List Solaris AI VirtualBox VMs

def list_ai_vbox_vms()
  search_string = "sol.11"
  list_vbox_vms(search_string)
  return
end

def list_vs_vbox_vms()
  search_string = "vmware"
  list_vbox_vms(search_string)
  return
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(client_name)
  message   = "Checking:\tVM "+client_name+" exists"
  command   = "VBoxManage list vms |grep -v 'inaccessible'"
  host_list = execute_command(message,command)
  if !host_list.match(client_name)
    puts "Information:\tVirtualBox VM "+client_name+" does not exist"
    exists = "no"
  else
    exists = "yes"
  end
  return exists
end

# Get VirtualBox bridged network interface

def get_bridged_vbox_nic()
  message  = "Checking:\tBridged interfaces"
  command  = "VBoxManage list bridgedifs"
  nic_list = execute_command(message,command)
  nic_name = ""
  if !nic_list.match(/[A-z]/)
    nic_name = $default_net
  else
    nic_list=nic_list.split(/\n/)
    nic_list.each do |line|
      line=line.chomp
      if line.match(/#{$default_host}/)
        return nic_name
      end
      if line.match(/^Name/)
        nic_name = line.split(/:/)[1].gsub(/\s+/,"")
      end
    end
  end
  return nic_name
end

# Add bridged network to VirtualBox VM

def add_bridged_network_to_vbox_vm(client_name,nic_name)
  message = "Adding:\tBridged network "+nic_name+" to "+client_name
  command = "VBoxManage modifyvm #{client_name} --nic1 bridged --bridgeadapter1 #{nic_name}"
  execute_command(message,command)
  return
end

# Add non-bridged network to VirtualBox VM

def add_nonbridged_network_to_vbox_vm(client_name,nic_name)
  message = "Adding:\t\tNetwork "+nic_name+" to "+client_name
  if nic_name.match(/vboxnet/)
    command = "VBoxManage modifyvm #{client_name} --hostonlyadapter1 #{nic_name} ; VBoxManage modifyvm #{client_name} --nic1 hostonly"
  else
    command = "VBoxManage modifyvm #{client_name} --nic1 #{nic_name}"
  end
  execute_command(message,command)
  return
end

# Set boot priority to network

def set_vbox_vm_boot_priority(client_name)
  message = "Setting:\tBoot priority for "+client_name+" to disk then network"
  command = "VBoxManage modifyvm #{client_name} --boot1 disk --boot2 net"
  execute_command(message,command)
  return
end

# List VirtualBox VMs

def list_vbox_vms(search_string)
  message = "Available VirtualBox VMs:"
  command = "VBoxManage list vms |grep -v 'inaccessible' |awk '{print $1}'"
  vm_list = execute_command(message,command)
  vm_list = vm_list.split(/\n/)
  vm_list.each do |vm_name|
    vm_mac = get_vbox_vm_mac(vm_name)
    output = vm_name+" "+vm_mac
    if search_string.match(/[A-z]/)
      if output.match(/#{search_string}/)
        puts output
      end
    else
      puts output
    end
  end
  return
end

# Get VirtualBox VM directory

def get_vbox_vm_dir(client_name)
  message          = "Getting:\tVirtualBox VM directory"
  command          = "VBoxManage list systemproperties |grep 'Default machine folder' |cut -f2 -d':' |sed 's/^[         ]*//g'"
  vbox_vm_base_dir = execute_command(message,command)
  vbox_vm_base_dir = vbox_vm_base_dir.chomp
  if !vbox_vm_base_dir.match(/[A-z]/)
    vbox_vm_base_dir=$home_dir+"/VirtualBox VMs"
  end
  vbox_vm_dir      = "#{vbox_vm_base_dir}/#{client_name}"
  return vbox_vm_dir
end

# Delete VirtualBox config file

def delete_vbox_vm_config(client_name)
  vbox_vm_dir = get_vbox_vm_dir(client_name)
  config_file = vbox_vm_dir+"/"+client_name+".vbox"
  if File.exist?(config_file)
    message = "Removing:\tVirtualbox configuration file "+config_file
    command = "rm \"#{config_file}\""
    execute_command(message,command)
  end
  return
end

# Check if VirtuakBox config file exists

def check_vbox_vm_config_exists(client_name)
  exists      = "no"
  vbox_vm_dir = get_vbox_vm_dir(client_name)
  config_file = vbox_vm_dir+"/"+client_name+".vbox"
  if File.exist?(config_file)
    exists = "yes"
  else
    exists = "no"
  end
  return exists
end

# Check VM doesn't exist

def check_vbox_vm_doesnt_exist(client_name)
  message   = "Checking:\tVM "+client_name+" doesn't exist"
  command   = "VBoxManage list vms"
  host_list = execute_command(message,command)
  if host_list.match(client_name)
    puts "Information:\tVirtualBox VM #{client_name} already exists"
    exit
  end
  return
end

# Routine to register VM

def register_vbox_vm(client_name,client_os)
  message = "Registering:\tVM "+client_name
  command = "VBoxManage createvm --name \"#{client_name}\" --ostype \"#{client_os}\" --register"
  execute_command(message,command)
  return
end

# Get VirtualBox disk

def get_vbox_controller()
  if $vbox_disk_type =~/ide/
    vbox_controller = "PIIX4"
  end
  if $vbox_disk_type =~/sata/
    vbox_controller = "IntelAhci"
  end
  if $vbox_disk_type =~/scsi/
    vbox_controller = "LSILogic"
  end
  if $vbox_disk_type =~/sas/
    vbox_controller = "LSILogicSAS"
  end
  return vbox_controller
end

# Add controller to VM

def add_controller_to_vbox_vm(client_name,vbox_controller)
  message = "Adding:\t\tController to VirtualBox VM"
  command = "VBoxManage storagectl \"#{client_name}\" --name \"#{$vbox_disk_type}\" --add \"#{$vbox_disk_type}\" --controller \"#{vbox_controller}\""
  execute_command(message,command)
  return
end

# Create Virtual Bpx VM HDD

def create_vbox_hdd(client_name,vbox_disk_name)
  message = "Creating:\tVM hard disk for "+client_name
  command = "VBoxManage createhd --filename \"#{vbox_disk_name}\" --size \"#{$default_vm_size}\""
  execute_command(message,command)
  return
end

# Add hard disk to VirtualBox VM

def add_hdd_to_vbox_vm(client_name,vbox_disk_name)
  message = "Attaching:\tStorage to VM "+client_name
  command = "VBoxManage storageattach \"#{client_name}\" --storagectl \"#{$vbox_disk_type}\" --port 0 --device 0 --type hdd --medium \"#{vbox_disk_name}\""
  execute_command(message,command)
  return
end

# Add hard disk to VirtualBox VM

def add_cdrom_to_vbox_vm(client_name)
  message = "Attaching:\tCDROM to VM "+client_name
  command = "VBoxManage storagectl \"#{client_name}\" --name \"cdrom\" --add \"sata\" --controller \"IntelAHCI\""
  execute_command(message,command)
  if File.exist?($vbox_additions_iso)
    message = "Attaching:\tISO "+$vbox_additions_iso+" to VM "+client_name
    command = "VBoxManage storageattach \"#{client_name}\" --storagectl \"cdrom\" --port 0 --device 0 --type dvddrive --medium \"#{$vbox_additions_iso}\""
    execute_command(message,command)
  end
  return
end

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(client_name)
  message = "Adding:\t\tMemory to VM "+client_name
  command = "VBoxManage modifyvm \"#{client_name}\" --memory \"#{$default_vm_mem}\""
  execute_command(message,command)
  return
end

# Routine to add a socket to a VM

def add_socket_to_vbox_vm(client_name)
  socket_name = "/tmp/#{client_name}"
  message     = "Adding:\t\tSerial controller to "+client_name
  command     = "VBoxManage modifyvm \"#{client_name}\" --uartmode1 server #{socket_name}"
  execute_command(message,command)
  return socket_name
end

# Routine to add serial to a VM

def add_serial_to_vbox_vm(client_name)
  message = "Adding:\t\tSerial Port to "+client_name
  command = "VBoxManage modifyvm \"#{client_name}\" --uart1 0x3F8 4"
  execute_command(message,command)
  return
end

# Configure a AI Virtual Box VM

def configure_ai_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os="Solaris11_64"
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a Jumpstart Virtual Box VM

def configure_js_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "OpenSolaris_64"
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a RedHat or Centos Kickstart VirtualBox VM

def configure_ks_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  if client_arch.match(/i386/)
    client_os = "RedHat"
  else
    client_os = "RedHat_64"
  end
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a Preseed Ubuntu VirtualBox VM

def configure_ps_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "Ubuntu"
  if client_arch.match(/x86_64/)
    client_os = client_os+"_64"
  end
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a AutoYast SuSE VirtualBox VM

def configure_ay_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "OpenSUSE"
  if client_arch.match(/x86_64/)
    client_os = client_os+"_64"
  end
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure an OpenBSD VM

def configure_ob_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "Linux_64"
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a NetBSD VM

def configure_nb_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "NetBSD"
  if client_arch.match(/x86_64/)
    client_os = client_os+"_64"
  end
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end


# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "Linux_64"
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

def modify_vbox_vm(client_name,param_name,param_value)
  message = "Setting:\tVirtualBox Parameter "+param_name+" to "+param_value
  command = "VBoxManage modifyvm #{client_name} --#{param_name} #{param_value}"
  execute_command(message,command)
  return
end

def setextradata_vbox_vm(client_name,param_name,param_value)
  message = "Setting:\tVirtualBox Extradata "+param_name+" to "+param_value
  command = "VBoxManage setextradata #{client_name} \"#{param_name}\" \"#{param_value}\""
  execute_command(message,command)
  return
end

# Change VirtualBox VM Cores

def change_vbox_vm_cpu(client_name,client_cpus)
  message = "Setting:\tVirtualBox VM "+client_name+" CPUs to "+client_cpus
  command = "VBoxManage modifyvm #{client_name} --cpus #{client_cpus}"
  execute_command(message,command)
  return
end

# Change VirtualBox VM Cores

def change_vbox_vm_utc(client_name,client_utc)
  message = "Setting:\tVirtualBox VM "+client_name+" RTC to "+client_utc
  command = "VBoxManage modifyvm #{client_name} --rtcuseutc #{client_utc}"
  execute_command(message,command)
  return
end

# Change VirtualBox VM MAC address

def change_vbox_vm_mac(client_name,client_mac)
  message = "Setting:\tVirtualBox VM "+client_name+" MAC address to "+client_mac
  if client_mac.match(/:/)
    client_mac = client_mac.gsub(/:/,"")
  end
  command = "VBoxManage modifyvm #{client_name} --macaddress1 #{client_mac}"
  execute_command(message,command)
  return
end

# Boot VirtualBox VM

def boot_vbox_vm(client_name)
  check_vbox_hostonly_network()
  exists = check_vbox_vm_exists(client_name)
  if exists == "no"
    puts "VirtualBox VM "+client_name+" does not exist"
    exit
  end
  message = "Starting:\tVM "+client_name
  if $text_mode == 1 or $serial_mode == 1
    puts
    puts "Information:\tBooting and connecting to virtual serial port of "+client_name
    puts
    puts "To disconnect from this session use CTRL-Q"
    puts
    puts "If you wish to re-connect to the serial console of this machine,"
    puts "run the following command"
    puts
    puts "socat UNIX-CONNECT:/tmp/#{client_name} STDIO,raw,echo=0,escape=0x11,icanon=0"
    puts
    %x[VBoxManage startvm #{client_name} --type headless ; sleep 1]
  else
    command = "VBoxManage startvm #{client_name}"
    execute_command(message,command)
  end
  if $serial_mode == 1
    system("socat UNIX-CONNECT:/tmp/#{client_name} STDIO,raw,echo=0,escape=0x11,icanon=0")
  else
    puts
    puts "If you wish to connect to the serial console of this machine,"
    puts "run the following command"
    puts
    puts "socat UNIX-CONNECT:/tmp/#{client_name} STDIO,raw,echo=0,escape=0x11,icanon=0"
    puts
    puts "To disconnect from this session use CTRL-Q"
    puts
    puts
  end
  return
end

# Stop VirtualBox VM

def stop_vbox_vm(client_name)
  message = "Stopping:\tVM "+client_name
  command = "VBoxManage controlvm #{client_name} poweroff"
  execute_command(message,command)
  return
end

# Get VirtualBox VM MAC address

def get_vbox_vm_mac(client_name)
  message  = "Getting:\tMAC address for "+client_name
  command  = "VBoxManage showvminfo #{client_name} |grep MAC |awk '{print $4}'"
  vbox_vm_mac = execute_command(message,command)
  vbox_vm_mac = vbox_vm_mac.chomp
  vbox_vm_mac = vbox_vm_mac.gsub(/\,/,"")
  return vbox_vm_mac
end

# Check VirtualBox hostonly network

def check_vbox_hostonly_network()
  message = "Checking:\tVirtualBox hostonly network exists"
  command = "VBoxManage list hostonlyifs |grep '^Name' |awk '{print $2}' |head -1"
  if_name = execute_command(message,command)
  if_name = if_name.chomp
  if !if_name.match(/vboxnet/)
    message = "Plumbing:\tVirtualBox hostonly network"
    command = "VBoxManage hostonlyif create"
    execute_command(message,command)
    message = "Finding:\tVirtualBox hostonly network name"
    command = "VBoxManage list hostonlyifs |grep '^Name' |awk '{print $2}' |head -1"
    if_name = execute_command(message,command)
    if_name = if_name.chomp
    if_name = if_name.gsub(/'/,"")
    message = "Disabling:\tDHCP on "+if_name
    command = "VBoxManage dhcpserver remove --ifname #{if_name}"
    execute_command(message,command)
  end
  message = "Checking:\tVirtualBox hostonly network "+if_name+" has address "+$default_hostonly_ip
  command = "VBoxManage list hostonlyifs |grep 'IPAddress' |awk '{print $2}' |head -1"
  host_ip = execute_command(message,command)
  host_ip = host_ip.chomp
  if !host_ip.match(/#{$default_hostonly_ip}/)
    message = "Configuring:\tVirtualBox hostonly network "+if_name+" with IP "+$default_hostonly_ip
    command = "VBoxManage hostonlyif ipconfig #{if_name} --ip #{$default_hostonly_ip} --netmask #{$default_netmask}"
    execute_command(message,command)
  end
  gw_if_name = get_osx_gw_if_name()
  check_osx_nat(gw_if_name,if_name)
  return if_name
end

# Check VirtualBox is installed

def check_vbox_is_installed()
  app_dir = "/Applications/VirtualBox.app"
  if !File.directory?(app_dir)
    puts "Warning:\tVirtualbox not installed"
    exit
  end
end

# Configure a VirtualBox VM

def configure_vbox_vm(client_name,client_mac,client_os)
  check_vbox_is_installed()
  if $default_vm_network.match(/hostonly/)
    vbox_nic_name = check_vbox_hostonly_network()
  end
  vbox_vm_dir      = get_vbox_vm_dir(client_name)
  vbox_disk_name   = vbox_vm_dir+"/"+client_name+".vdi"
  vbox_socket_name = "/tmp/#{client_name}"
  vbox_controller  = get_vbox_controller()
  check_vbox_vm_doesnt_exist(client_name)
  register_vbox_vm(client_name,client_os)
  add_controller_to_vbox_vm(client_name,vbox_controller)
  create_vbox_hdd(client_name,vbox_disk_name)
  add_hdd_to_vbox_vm(client_name,vbox_disk_name)
  add_memory_to_vbox_vm(client_name)
  vbox_socket_name = add_socket_to_vbox_vm(client_name)
  add_serial_to_vbox_vm(client_name)
  if $default_vm_network.match(/bridged/)
    vbox_nic_name = get_bridged_vbox_nic()
    add_bridged_network_to_vbox_vm(client_name,vbox_nic_name)
  else
    add_nonbridged_network_to_vbox_vm(client_name,vbox_nic_name)
  end
  set_vbox_vm_boot_priority(client_name)
  add_cdrom_to_vbox_vm(client_name)
  if client_mac.match(/[0-9]/)
    change_vbox_vm_mac(client_name,client_mac)
  else
    client_mac = get_vbox_vm_mac(client_name)
  end
  if $client_os == "ESXi"
    configure_vmware_esxi_vbox_vm(client_name)
  end
  puts "Created:\tVirtualBox VM "+client_name+" with MAC address "+client_mac
  return
end


# Check VirtualBox NATd

def check_vbox_natd()
  check_vbox_is_installed()
  if $default_vm_network.match(/hostonly/)
    check_vbox_hostonly_network()
  end
  return
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(client_name)
  check_vbox_is_installed()
  exists = check_vbox_vm_exists(client_name)
  if exists == "no"
    puts "VirtualBox VM "+client_name+" does not exist"
    exit
  end
  stop_vbox_vm(client_name)
  message = "Deleting:\tVirtualBox VM "+client_name
  command = "VBoxManage unregistervm #{client_name} --delete"
  execute_command(message,command)
  return
end
