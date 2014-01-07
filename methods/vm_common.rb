
# Code for creating client VMs for testing (e.g. VirtualBox)

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
    puts "VM #{client_name} already exists"
    exit
  end
  return
end

# Routine to register VM

def register_vbox_vm(client_name,os_type)
  message = "Registering:\tVM "+client_name
  command = "VBoxManage createvm --name \"#{client_name}\" --ostype \"#{os_type}\" --register"
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

# Configure a AI VM

def configure_ai_vbox_vm(client_name,client_mac,client_arch)
  os_type="Solaris11_64"
  configure_vbox_vm(client_name,client_mac,os_type)
  return
end

# Configure a Jumpstart VM

def configure_js_vbox_vm(client_name,client_mac,client_arch)
  os_type = "OpenSolaris_64"
  configure_vbox_vm(client_name,client_mac,os_type)
  return
end

# Configure a Kickstart VM

def configure_ks_vbox_vm(client_name,client_mac,client_arch)
  if client_arch.match(/i386/)
    os_type = "RedHat"
  else
    os_type = "RedHat_64"
  end
  configure_vbox_vm(client_name,client_mac,os_type)
  return
end

# List Linux KS VMs

def list_ks_vbox_vms()
  search_string=""
  list_vbox_vms(search_string)
  return
end

# List Solaris Kickstart VMs

def list_js_vbox_vms()
  search_string=""
  list_vbox_vms(search_string)
  return
end

# List Solaris AI VMs

def list_ai_vbox_vms()
  search_string=""
  list_vbox_vms(search_string)
  return
end

# List VirtualBox VMs

def list_vbox_vms(search_string)
  message = "Available VMs:"
  command = "VBoxManage list vms"
  output  = execute_command(message,command)
  puts output
  return
end

# Check VirtualBox VM exists

def check_vbox_vm_exists(client_name)
  message="Checking:\tVM "+client_name+" exists"
  command="VBoxManage list vms |grep -v 'inaccessible'"
  host_list=execute_command(message,command)
  if !host_list.match(client_name)
    puts "Information:\tVM "+client_name+" does not exist"
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

# Set boot priority to network

def set_vbox_vm_boot_priority(client_name)
  message = "Setting:\tBoot priority for "+client_name+" to network"
  command = "VBoxManage modifyvm #{client_name} --boot1 net"
  return
end

# Configure a VirtualBox VM

def configure_vbox_vm(client_name,client_macn,os_type)
  vbox_vm_dir      = get_vbox_vm_dir(client_name)
  vbox_disk_name   = vbox_vm_dir+"/"+client_name+".vdi"
  vbox_socket_name = "/tmp/#{client_name}"
  vbox_controller  = get_vbox_controller()
  check_vbox_vm_doesnt_exist(client_name)
  register_vbox_vm(client_name,os_type)
  add_controller_to_vbox_vm(client_name,vbox_controller)
  create_vbox_hdd(client_name,vbox_disk_name)
  add_hdd_to_vbox_vm(client_name,vbox_disk_name)
  add_memory_to_vbox_vm(client_name)
  vbox_socket_name = add_socket_to_vbox_vm(client_name)
  add_serial_to_vbox_vm(client_name)
  vbox_nic_name=get_bridged_vbox_nic()
  add_bridged_network_to_vbox_vm(client_name,vbox_nic_name)
  set_vbox_vm_boot_priority(client_name)
  if client_mac.match(/[0-9]/)
    change_vbox_vm_mac(client_name,client_mac)
  end
  return
end

# Unconfigure a VM

def unconfigure_vbox_vm(client_name)
  check_vbox_vm_exists(client_name)
  message = "Deleting:\tVirtualBox VM "+client_name
  command = "VBoxManage unregistervm #{client_name} --delete"
  execute_command(message,command)
  return
end

# Boot VirtualBox VM in headless mode

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
  vbox_mac = execute_command(message,command)
  vbox_mac = vbox_mac.gsub(/\,/,"")
  puts "MAC Address for "+client_name+":"
  puts vbox_mac
  return
end

def change_vbox_vm_mac(client_name,client_mac)
  message = "Setting:\tVirtualBox VM "+client_name+" MAC address to "+client_mac
  if client_mac.match(/:/)
    client_mac = client_mac.gsub(/:/,"")
  end
  command = "VBoxManage modifyvm #{client_name} --macaddress1 #{client_mac}"
  execute_command(message,command)
  return
end
