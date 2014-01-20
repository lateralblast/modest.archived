
# Code for creating client VMs for testing (e.g. VirtualBox)

# List available zones

def list_zones()
  puts "Available Zones:"
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(message,command)
  puts output
  return
end

# Create zone

def create_zone(client_name,zone_dir,output_file,client_rel)
  if $os_rel.match(/11/) and client_rel.match(/10/)
    branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
    branded_dir = "/export/zones"
    if $os_arch.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_zfs_fs_exists(branded_dir)
    if !File.exists(branded_file)
      puts "Warning:\tBranded zone templates not found"
      puts "Information:\tDownload them from "+branded_url
      puts "Information:\tCopy them to "+branded_dir
    end
  end
  zone_nic = $q_struct["ipv4_interface_name"].value
  message = "Creating:\tSolaris "+client_rel+" Zone "+client_name=" in "+zone_dir
  command = "zonecfg -z #{client_name} -f #{output_file} \"create ; set zonepath=#{zone_dir} ; exit\""
  execute_command(message,command)
  message = "Setting:\tZone interface to "+zone_nic
  command = "zonecfg -z #{client_name} \"select anet linkname=#{zone_nic} ; end\""
  execute_command(message,command)
  message = "Installing:\tZone "+client_name
  command = "zoneadm -z #{client_name} install"
  execute_command(message,command)
  if $use_serial == 1
    system("zlogin #{client_name}")
  end
  return
end

# Delete zone

def unconfigure_zone(client_name)
  message = "Deleting:\tZone "+client_name
  command = "zonecfg -z #{client_name}"
  execute_command(message,command)
  return
end

# Boot zone

def boot_zone(client_name)
  message = "Booting:\tZone "+client_name
  command = "zoneadm -z #{client_name} boot"
  execute_command(message,command)
  return
end

# Shutdown zone

def stop_zone(client_name)
  message = "Stopping:\tZone "+client_name
  command = "zlogin #{client_name} \"shutdown -y -i 0\""
  execute_command(message,command)
  return
end

# Configure zone

def configure_zone(client_name,client_mac,client_arch,client_os,client_rel)
  if client_rel.match(/11/)
    populate_ai_client_profile_questions(client_ip,client_name)
    output_file = $work_dir+"/"+client_name+"_zone_profile.xml"
    process_questions()
    create_zone_profile_xml(output_file)
  else
    populate_js_client_profile_questions(client_ip,client_name)
    output_file = $work_dir+"/"+client_name+"_zone_profile.sysidcfg"
    process_questions()
    create_zone_profile_sysidcfg(output_file)
  end
  check_zfs_fs_exists($zone_base_dir)
  zone_dir = $zone_base_dir+"/"+client_name
  create_zone(client_name,zone_dir,output_file,client_rel)
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
    vbox_controller = "LsiLogic"
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
  command = "VBoxManage createhd --filename \"#{vbox_disk_name}\" --size \"#{$vm_disk_size}\""
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

# Add memory to Virtualbox VM

def add_memory_to_vbox_vm(client_name)
  message = "Adding:\t\tMemory to VM "+client_name
  command = "VBoxManage modifyvm \"#{client_name}\" --memory \"#{$vm_memory_size}\""
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

# Configure a ESX VirtualBox VM

def configure_vs_vbox_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "Linux_64"
  configure_vbox_vm(client_name,client_mac,client_os)
  return
end

# Configure a AI VMware Fusion VM

def configure_ai_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os="solaris11-64"
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure a Jumpstart VMware Fusion VM

def configure_js_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "solaris10-64"
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# configure an AutoYast (Suse) VMware Fusion VM

def configure_ay_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "sles11"
  if !client_arch.match(/i386/) and !client_arch.match(/64/)
    client_os = client_os+"-64"
  end
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure an Ubuntu VMware Fusion VM

def configure_ps_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "ubuntu"
  if !client_arch.match(/i386/) and !client_arch.match(/64/)
    client_os = client_os+"-64"
  end
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure a Windows VMware Fusion VM

def configure_pe_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "windows7srv-64"
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure a Kickstart VMware Fusion VM

def configure_ks_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  if !client_os or !client_os.match(/[A-z]/)
    if client_name.match(/ubuntu/)
      client_os = "ubuntu"
    end
    if client_name.match(/centos|redhat|rhel/)
      client_os = "rhel5"
    end
  end
  if !client_arch.match(/i386/) and !client_arch.match(/64/)
    client_os = client_os+"-64"
  end
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure a ESX VMware Fusion VM

def configure_vs_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "vmkernel5"
  configure_fusion_vm(client_name,client_mac,client_os)
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

# List Solaris ESX VirtualBox VMs

def list_vs_fusion_vms()
  search_string = "vmware"
  list_fusion_vms(search_string)
  return
end

# List Linux KS VMware Fusion VMs

def list_ks_fusion_vms()
  search_string = "rhel|centos|ubuntu"
  list_fusion_vms(search_string)
  return
end

# List Solaris Kickstart VMware Fusion VMs

def list_js_fusion_vms()
  search_string = "sol.10"
  list_fusion_vms(search_string)
  return
end

# List Solaris AI VMware Fusion VMs

def list_ai_fusion_vms()
  search_string = "sol.11"
  list_fusion_vms(search_string)
  return
end

# List Solaris ESX VMware Fusion VMs

def list_vs_vbox_vms()
  search_string = "vmware"
  list_vbox_vms(search_string)
  return
end

# List VirtualBox VMs

def list_vbox_vms(search_string)
  message = "Available VirtualBox VMs:"
  command = "VBoxManage list vms |grep -v 'inaccessible' |awk '{print $1}'"
  vm_list = execute_command(message,command)
  vm_list = vm_list.split(/\n/)
  vm_list.each do |vm_name|
    vm_mac = get_vbox_vm_mac(vbox_vm_name)
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

# Get Fusion VM MAC address

def get_fusion_vm_mac(vmx_file)
  vm_config = ParseConfig.new(vmx_file)
  vm_mac    = vm_config["ethernet0.address"]
  if !vm_mac
    vm_mac  = vm_config["ethernet0.generatedAddress"]
  end
  return vm_mac
end

# List Fusion VMs

def list_fusion_vms(search_string)
  message = "Available VMware Fusion VMs:"
  command = "find '#{$fusion_dir}' -name '*.vmx'"
  vm_list = execute_command(message,command)
  vm_list = vm_list.split(/\n/)
  vm_list.each do |vmx_file|
    vm_name = File.basename(vmx_file,".vmx")
    vm_mac  = get_fusion_vm_mac(vmx_file)
    output  = vm_name+" "+vm_mac
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

# Check VMware Fusion VM exists

def check_fusion_vm_exists(client_name)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  if !File.exists?(fusion_vmx_file)
    puts "Information:\tVMware Fusion VM "+client_name+" does not exist"
    exit
  end
end

# Check VMware Fusion VM doesn't exist

def check_fusion_vm_doesnt_exist(client_name)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  fusion_disk_file = fusion_vm_dir+"/"+client_name+".vmdk"
  if File.exists?(fusion_vmx_file)
    puts "Information:\tVMware Fusion VM "+client_name+" already exists"
    exit
  end
  return fusion_vm_dir,fusion_vmx_file,fusion_disk_file
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

# Set boot priority to network

def set_vbox_vm_boot_priority(client_name)
  message = "Setting:\tBoot priority for "+client_name+" to network"
  command = "VBoxManage modifyvm #{client_name} --boot1 net"
  execute_command(message,command)
  return
end

# Create VMware Fusion VM disk

def create_fusion_vm_disk(client_name,fusion_vm_dir,fusion_disk_file)
  if File.exists?(fusion_disk_file)
    puts "Warning:\tVMware Fusion VM disk '"+fusion_disk_file+"' already exists for "+client_name
    exit
  end
  check_dir_exists(fusion_vm_dir)
  vdisk_bin = "/Applications/VMware Fusion.app//Contents/Library/vmware-vdiskmanager"
  message   = "Creating:\tVMware Fusion disk '"+fusion_disk_file+"' for "+client_name
  command   = "cd '#{fusion_vm_dir}' ; '#{vdisk_bin}' -c -s '#{$vm_disk_size}' -a LsiLogic -t 1 '#{fusion_disk_file}'"
  execute_command(message,command)
  return
end

# Populate VMware Fusion VM vmx information

def populate_fusion_vm_vmx_info(client_name,client_mac,client_os)
  vmx_info = []
  vmx_info.push(".encoding,UTF-8")
  vmx_info.push("config.version,8")
  vmx_info.push("virtualHW.version,10")
  vmx_info.push("vcpu.hotadd,TRUE")
  vmx_info.push("scsi0.present,TRUE")
  if client_os.match(/windows7srv-64/)
    vmx_info.push("scsi0.virtualDev,lsisas1068")
  else
    vmx_info.push("scsi0.virtualDev,lsilogic")
  end
  vmx_info.push("sata0.present,TRUE")
  vmx_info.push("memsize,#{$vm_memory_size}")
  vmx_info.push("mem.hotadd,TRUE")
  vmx_info.push("scsi0:0.present,TRUE")
  vmx_info.push("scsi0:0.fileName,#{client_name}.vmdk")
  vmx_info.push("sata0:1.present,FALSE")
  vmx_info.push("floppy0.fileType,device")
  vmx_info.push("floppy0.fileName,")
  vmx_info.push("floppy0.clientDevice,FALSE")
  vmx_info.push("ethernet0.present,TRUE")
  vmx_info.push("ethernet0.connectionType,bridged")
  vmx_info.push("ethernet0.virtualDev,e1000")
  vmx_info.push("ethernet0.wakeOnPcktRcv,FALSE")
  vmx_info.push("ethernet0.addressType,static")
  vmx_info.push("ethernet0.linkStatePropagation.enable,TRUE")
  vmx_info.push("usb.present,TRUE")
  vmx_info.push("ehci.present,TRUE")
  vmx_info.push("ehci.pciSlotNumber,35")
  vmx_info.push("sound.present,TRUE")
  if client_os.match(/windows7srv-64/)
    vmx_info.push("sound.virtualDev,hdaudio")
  end
  vmx_info.push("sound.fileName,-1")
  vmx_info.push("sound.autodetect,TRUE")
  vmx_info.push("mks.enable3d,TRUE")
  vmx_info.push("pciBridge0.present,TRUE")
  vmx_info.push("pciBridge4.present,TRUE")
  vmx_info.push("pciBridge4.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge4.functions,8")
  vmx_info.push("pciBridge5.present,TRUE")
  vmx_info.push("pciBridge5.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge5.functions,8")
  vmx_info.push("pciBridge6.present,TRUE")
  vmx_info.push("pciBridge6.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge6.functions,8")
  vmx_info.push("pciBridge7.present,TRUE")
  vmx_info.push("pciBridge7.virtualDev,pcieRootPort")
  vmx_info.push("pciBridge7.functions,8")
  vmx_info.push("vmci0.present,TRUE")
  vmx_info.push("hpet0.present,TRUE")
  vmx_info.push("usb.vbluetooth.startConnected,TRUE")
  vmx_info.push("tools.syncTime,TRUE")
  vmx_info.push("displayName,#{client_name}")
  vmx_info.push("guestOS,#{client_os}")
  vmx_info.push("nvram,#{client_name}.nvram")
  vmx_info.push("virtualHW.productCompatibility,hosted")
  vmx_info.push("tools.upgrade.policy,upgradeAtPowerCycle")
  vmx_info.push("powerType.powerOff,soft")
  vmx_info.push("powerType.powerOn,soft")
  vmx_info.push("powerType.suspend,soft")
  vmx_info.push("powerType.reset,soft")
  vmx_info.push("extendedConfigFile,#{client_name}.vmxf")
  vmx_info.push("uuid.bios,56")
  vmx_info.push("uuid.location,56")
  vmx_info.push("replay.supported,FALSE")
  vmx_info.push("replay.filename,")
  vmx_info.push("pciBridge0.pciSlotNumber,17")
  vmx_info.push("pciBridge4.pciSlotNumber,21")
  vmx_info.push("pciBridge5.pciSlotNumber,22")
  vmx_info.push("pciBridge6.pciSlotNumber,23")
  vmx_info.push("pciBridge7.pciSlotNumber,24")
  vmx_info.push("scsi0.pciSlotNumber,16")
  vmx_info.push("usb.pciSlotNumber,32")
  vmx_info.push("ethernet0.pciSlotNumber,33")
  vmx_info.push("sound.pciSlotNumber,34")
  vmx_info.push("vmci0.pciSlotNumber,36")
  vmx_info.push("sata0.pciSlotNumber,37")
  if client_os.match(/windows7srv-64/)
    vmx_info.push("scsi0.sasWWID,50 05 05 63 9c 8f c0 c0")
  end
  vmx_info.push("ethernet0.generatedAddressOffset,0")
  vmx_info.push("vmci0.id,-1176557972")
  vmx_info.push("vmotion.checkpointFBSize,134217728")
  vmx_info.push("cleanShutdown,TRUE")
  vmx_info.push("softPowerOff,FALSE")
  vmx_info.push("usb:1.speed,2")
  vmx_info.push("usb:1.present,TRUE")
  vmx_info.push("usb:1.deviceType,hub")
  vmx_info.push("usb:1.port,1")
  vmx_info.push("usb:1.parent,-1")
  vmx_info.push("checkpoint.vmState,")
  vmx_info.push("sata0:1.startConnected,FALSE")
  vmx_info.push("usb:0.present,TRUE")
  vmx_info.push("usb:0.deviceType,hid")
  vmx_info.push("usb:0.port,0")
  vmx_info.push("usb:0.parent,-1")
  vmx_info.push("ethernet0.address,#{client_mac}")
  vmx_info.push("floppy0.present,FALSE")
  vmx_info.push("serial0.present,TRUE")
  vmx_info.push("serial0.fileType,pipe")
  vmx_info.push("serial0.yieldOnMsrRead,TRUE")
  vmx_info.push("serial0.startConnected,TRUE")
  vmx_info.push("serial0.fileName,/tmp/#{client_name}")
  vmx_info.push("scsi0:0.redo,")
  return vmx_info
end

# Create VMware Fusion VM vmx file

def create_fusion_vm_vmx_file(client_name,client_mac,client_os,fusion_vmx_file)
  vmx_info = populate_fusion_vm_vmx_info(client_name,client_mac,client_os)
  file = File.open(fusion_vmx_file,"w")
  vmx_info.each do |vmx_line|
    (vmx_param,vmx_value) = vmx_line.split(/\,/)
    if !vmx_value
      vmx_value = ""
    end
    output = vmx_param+" = \""+vmx_value+"\"\n"
    file.write(output)
  end
  file.close
  if $verbose_mode == 1
    puts "Information:\tVMware Fusion VM "+client_name+" configuration:"
    system("cat '#{fusion_vmx_file}'")
  end
  return
end

# Configure a VMware Fusion VM

def configure_fusion_vm(client_name,client_mac,client_os)
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(client_name)
  check_dir_exists(fusion_vm_dir)
  create_fusion_vm_vmx_file(client_name,client_mac,client_os,fusion_vmx_file)
  create_fusion_vm_disk(client_name,fusion_vm_dir,fusion_disk_file)
  return
end

# Configure a VirtualBox VM

def configure_vbox_vm(client_name,client_mac,client_os)
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
  vbox_nic_name = get_bridged_vbox_nic()
  add_bridged_network_to_vbox_vm(client_name,vbox_nic_name)
  set_vbox_vm_boot_priority(client_name)
  if client_mac.match(/[0-9]/)
    change_vbox_vm_mac(client_name,client_mac)
  else
    client_mac = get_vbox_vm_mac(client_name)
  end
  puts "Created:\tVirtualBox VM "+client_name+" with MAC address "+client_mac
  return
end

# Unconfigure a VMware Fusion VM

def unconfigure_fusion_vm(client_name)
  check_fusion_vm_exists(client_name)
  stop_fusion_vm(client_name)
  vmrun_bin        = "/Applications/VMware Fusion.app/Contents/Library/vmrun"
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  message          = "Deleting:\tVMware Fusion VM "+client_name
  command          = "'#{vmrun_bin}' -T fusion deleteVM '#{fusion_vmx_file}'"
  execute_command(message,command)
  vm_dir   = client_name+".vmwarevm"
  message  = "Removing:\tVMware Fusion VM "+client_name+" directory"
  command  = "cd '#{$fusion_dir}' ; rm -rf '#{vm_dir}'"
  execute_command(message,command)
  return
end

# Unconfigure a Virtual Box VM

def unconfigure_vbox_vm(client_name)
  check_vbox_vm_exists(client_name)
  stop_vbox_vm(client_name)
  message = "Deleting:\tVirtualBox VM "+client_name
  command = "VBoxManage unregistervm #{client_name} --delete"
  execute_command(message,command)
  return
end

# Boot VMware Fusion VM

def boot_fusion_vm(client_name)
  vmrun_bin        = "/Applications/VMware Fusion.app/Contents/Library/vmrun"
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  message          = "Starting:\tVM "+client_name
  if $text_install == 1
    command = "'#{vmrun_bin}' -T fusion start '#{fusion_vmx_file}' nogui"
  else
    command = "'#{vmrun_bin}' -T fusion start '#{fusion_vmx_file}'"
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

# Stop VMware Fusion VM

def stop_fusion_vm(client_name)
  vmrun_bin        = "/Applications/VMware Fusion.app//Contents/Library/vmrun"
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  message          = "Stopping:\tVirtual Box VM "+client_name
  command = "'#{vmrun_bin}' -T fusion stop '#{fusion_vmx_file}'"
  execute_command(message,command)
  return
end

# Boot VirtualBox VM

def boot_vbox_vm(client_name)
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
  vbox_vm_mac = vbox_vm_mac.gsub(/\,/,"")
  return vbox_vm_mac
end

# Get VMware Fusion VM MAC address

def change_fusion_vm_mac(client_name,client_mac)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  copy=[]
  file=IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/generatedAddress/)
      copy.push("ethernet0.address = \""+client_mac+"\"\n")
    else
      if line.match(/ethernet0\.address/)
        copy.push("ethernet0.address = \""+client_mac+"\"\n")
      else
        copy.push(line)
      end
    end
  end
  File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
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
