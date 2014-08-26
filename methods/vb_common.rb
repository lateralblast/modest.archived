# VirtualBox VM support code

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
    exit
  end
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
  message = "Starting:\tVM "+client_name
  if $text_install == 1
    command = "VBoxManage startvm #{client_name} --type headless"
  else
    command = "VBoxManage startvm #{client_name}"
  end
  execute_command(message,command)
  if $use_serial == 1
    if $verbose_mode == 1
      puts "Information:\tConnecting to serial port of "+client_name
    end
    begin
      socket = UNIXSocket.open("/tmp/#{client_name}")
      socket.each_line do |line|
        puts line
      end
    rescue
      puts "Cannot open socket"
      exit
    end
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
  check_vbox_vm_exists(client_name)
  stop_vbox_vm(client_name)
  message = "Deleting:\tVirtualBox VM "+client_name
  command = "VBoxManage unregistervm #{client_name} --delete"
  execute_command(message,command)
  return
end
