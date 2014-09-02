# VMware Fusion support code

# Get/set vmrun path

def set_vmrun_bin()
  $vmrun_bin = "/Applications/VMware Fusion.app/Contents/Library/vmrun"
  if !File.exist?($vmrun_bin)
    puts "Warning:\tCould not find vmrun"
    exit
  end
  return
end

# Get/set ovftool path

def set_ovftool_bin()
  $ovftool_bin = "/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"
  if !File.exist?($ovftool_bin)
    puts "Warning:\tCould not find ovftool"
    exit
  end
  return
end

# Get list of running vms

def get_running_fusion_vms()
  vm_list = %x["#{$vmrun_bin}" list |grep vmx].split("\n")
  return vm_list
end

# List running VMs

def list_running_fusion_vms()
  vm_list = get_running_fusion_vms()
  puts
  puts "Running VMs:"
  puts
  vm_list.each do |vm_name|
    vm_name = File.basename(vm_name,".vmx")
    puts vm_name
  end
  puts
  return
end

# Export OVA

def export_fusion_ova(client_name,ova_file)
  exists = check_fusion_vm_exists(client_name)
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
    message = "Information:\tExporting VMware Fusion VM "+client_name+" to "+fusion_vmx_file
    command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{client_name}\" \"#{fusion_vmx_file}\" \"#{ova_file}\""
    execute_command(message,command)
  else
    message = "Information:\tExporting VMware Fusion VM "+client_name+" to "+fusion_vmx_file
    command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{client_name}\" \"#{fusion_vmx_file}\" \"#{ova_file}\""
    execute_command(message,command)
  end
  return
end

# Import OVA

def import_fusion_ova(client_name,client_mac,client_ip,ova_file)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  exists = check_fusion_vm_exists(client_name)
  if exists == "no"
    if !ova_file.match(/\//)
      ova_file = $iso_base_dir+"/"+ova_file
    end
    if File.exist?(ova_file)
      if client_name.match(/[A-z]|[0-9]/)
        if !File.directory?(fusion_vm_dir)
          Dir.mkdir(fusion_vm_dir)
        end
        message = "Information:\tImporting VMware Fusion VM "+client_name+" from "+fusion_vmx_file
        command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{client_name}\" \"#{ova_file}\" \"#{fusion_vmx_file}\""
        execute_command(message,command)
      else
        client_name     = %x["#{$ovftool_bin}" "#{ova_file}" |grep Name |tail -1 |cut -f2 -d:].chomp
        client_name     = client_name.gsub(/\s+/,"")
        fusion_vmx_file = fusion_vm_dir+"/"+client_name+".vmx"
        if !client_name.match(/[A-z]|[0-9]/)
          puts "Warning:\tCould not determine VM name for Virtual Appliance "+ova_file
          exit
        else
          client_name = client_name.split(/Suggested VM name /)[1].chomp
          if !File.directory?(fusion_vm_dir)
            Dir.mkdir(fusion_vm_dir)
          end
          message = "Information:\tImporting VMware Fusion VM "+client_name+" from "+fusion_vmx_file
          command = "\"#{$ovftool_bin}\" --acceptAllEulas --name=\"#{client_name}\" \"#{ova_file}\" \"#{fusion_vmx_file}\""
          execute_command(message,command)
        end
      end
    else
      puts "Warning:\tVirtual Appliance "+ova_file+"does not exist"
    end
  end
  if client_ip.match(/[0-9]/)
    add_hosts_entry(client_name,client_ip)
  end
  if client_mac.match(/[0-9]|[A-F,a-f]/)
    change_fusion_vm_mac(client_name,client_mac)
  else
    client_mac = get_fusion_vm_mac(fusion_vmx_file)
  end
  change_fusion_vm_network(client_name,$default_vm_network)
  puts "Information:\tVirtual Appliance "+ova_file+" imported with VM name "+client_name+" and MAC address "+client_mac
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
  search_string = "rhel|centos|oel"
  list_fusion_vms(search_string)
  return
end

# List Linux Preseed VMware Fusion VMs

def list_ps_fusion_vms()
  search_string = "ubuntu"
  list_fusion_vms(search_string)
  return
end

# List Linux AutoYast VMware Fusion VMs

def list_ay_fusion_vms()
  search_string = "sles|suse"
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

# Get Fusion VM MAC address

def get_fusion_vm_mac(vmx_file)
  vm_config = ParseConfig.new(vmx_file)
  vm_mac    = vm_config["ethernet0.address"]
  if !vm_mac
    vm_mac  = vm_config["ethernet0.generatedAddress"]
  end
  return vm_mac
end

# Change VMware Fusion VM MAC address

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

# Check Fusion hostonly networking

def check_fusion_hostonly_network(if_name)
  config_file     = "/Library/Preferences/VMware Fusion/networking"
  network_address = $default_hostonly_ip.split(/\./)[0..2].join(".")+".0"
  gw_if_name      = get_osx_gw_if_name()
  test = 0
  copy = []
  file = IO.readlines(config_file)
  file.each do |line|
    case line
    when /answer VNET_1_DHCP /
      if !line.match(/no/)
        test = 1
        copy.push("answer VNET_1_DHCP no")
      else
        copy.push(line)
      end
    when /answer VNET_1_HOSTONLY_SUBNET/
      if !line.match(/#{network_address}/)
        test = 1
        copy.push("answer VNET_1_HOSTONLY_SUBNET #{network_address}")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  if test == 1
    vmnet_cli = "/Applications/VMware Fusion.app/Contents/Library/vmnet-cli"
    temp_file = "/tmp/networking"
    File.open(temp_file,"w") {|file_data| file_data.puts copy}
    message = "Configuring host only network on #{if_name} for network #{network_address}"
    command = "sudo -c 'cp #{temp_file} \"#{config_file}\"'"
    execute_command(message,command)
    message = "Restarting VMware network"
    command = "sudo sh -c '\"#{vmnet_cli} --configure\" ; \"#{vmnet_cli} --stop\" ; \"#{vmnet_cli}\" -- start'"
    execute_command(message,command)
  end
  check_osx_nat(gw_if_name,if_name)
  return
end

# Change VMware Fusion VM network type

def change_fusion_vm_network(client_name,client_network)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  test = 0
  copy = []
  file = IO.readlines(fusion_vmx_file)
  file.each do |line|
    if line.match(/ethernet0\.connectionType/)
      if !line.match(/#{client_network}/)
        test = 1
        copy.push("ethernet0.connectionType = \""+client_network+"\"\n")
      else
        copy.push(line)
      end
    else
      copy.push(line)
    end
  end
  if test == 1
    File.open(fusion_vmx_file,"w") {|file_data| file_data.puts copy}
  end
  return
end

# Boot VMware Fusion VM

def boot_fusion_vm(client_name)
  vm_list = get_available_fusion_vms()
  if vm_list.to_s.match(/#{client_name}/)
    fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
    fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
    message          = "Starting:\tVM "+client_name
    if $text_mode == 1
      command = "'#{$vmrun_bin}' -T fusion start '#{fusion_vmx_file}' nogui"
    else
      command = "'#{$vmrun_bin}' -T fusion start '#{fusion_vmx_file}'"
    end
    execute_command(message,command)
    if $serial_mode == 1
      if $verbose_mode == 1
        puts "Information:\tConnecting to serial port of "+client_name
      end
      begin
        socket = UNIXSocket.open("/tmp/#{client_name}")
        socket.each_line do |line|
          puts line
        end
      rescue
        puts "Warning:\tCannot open socket"
        exit
      end
    end
  else
    puts "VMware Fusion VM "+client_name+" does not exist"
  end
  return
end

# Stop VMware Fusion VM

def stop_fusion_vm(client_name)
  vm_list = get_running_fusion_vms()
  if vm_list.to_s.match(/#{client_name}/)
    fusion_vm_dir   = $fusion_dir+"/"+client_name+".vmwarevm"
    fusion_vmx_file = fusion_vm_dir+"/"+client_name+".vmx"
    message = "Stopping:\tVirtual Box VM "+client_name
    command = "'#{$vmrun_bin}' -T fusion stop '#{fusion_vmx_file}'"
    execute_command(message,command)
  else
    puts "VMware Fusion VM "+client_name+" not running"
  end
  return
end

# Create VMware Fusion VM disk

def create_fusion_vm_disk(client_name,fusion_vm_dir,fusion_disk_file)
  if File.exist?(fusion_disk_file)
    puts "Warning:\tVMware Fusion VM disk '"+fusion_disk_file+"' already exists for "+client_name
    exit
  end
  check_dir_exists(fusion_vm_dir)
  vdisk_bin = "/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
  message   = "Creating:\tVMware Fusion disk '"+fusion_disk_file+"' for "+client_name
  command   = "cd '#{fusion_vm_dir}' ; '#{vdisk_bin}' -c -s '#{$default_vm_size}' -a LsiLogic -t 1 '#{fusion_disk_file}'"
  execute_command(message,command)
  return
end


# Check VMware Fusion VM exists

def check_fusion_vm_exists(client_name)
  fusion_vm_dir   = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file = fusion_vm_dir+"/"+client_name+".vmx"
  if !File.exist?(fusion_vmx_file)
    exists = "no"
  else
    exists = "yes"
  end
  return exists
end

# Check VMware Fusion VM doesn't exist

def check_fusion_vm_doesnt_exist(client_name)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  fusion_disk_file = fusion_vm_dir+"/"+client_name+".vmdk"
  if File.exist?(fusion_vmx_file)
    puts "Information:\tVMware Fusion VM "+client_name+" already exists"
    exit
  end
  return fusion_vm_dir,fusion_vmx_file,fusion_disk_file
end

# Get a list of available VMware Fusion VMs

def get_available_fusion_vms()
  vm_list = %x[find "#{$fusion_dir}/" -name "*.vmx"].split("\n")
  return vm_list
end

# List available VMware Fusion VMs

def list_fusion_vms(search_string)
  puts
  puts "Available VMware Fusion VMs:"
  puts
  vm_list = get_available_fusion_vms()
  vm_list.each do |vmx_file|
    vm_name = File.basename(vmx_file,".vmx")
    vm_mac  = get_fusion_vm_mac(vmx_file)
    output  = vm_name+"\t"+vm_mac
    if search_string.match(/[A-z]/)
      if output.match(/#{search_string}/)
        puts output
      end
    else
      puts output
    end
  end
  puts
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

# Configure a NetBSB VMware Fusion VM

def configure_nb_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "freebsd"
  if !client_arch.match(/i386/) and !client_arch.match(/64/)
    client_os = client_os+"-64"
  end
  configure_fusion_vm(client_name,client_mac,client_os)
  return
end

# Configure an OpenBSD VMware Fusion VM

def configure_ob_fusion_vm(client_name,client_mac,client_arch,client_os,client_rel)
  client_os = "otherlinux-64"
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
    if client_name.match(/centos|redhat|rhel|sl|scientific|oel|suse/) or client_os.downcase.match(/centos|redhat|rhel|sl|scientific|oel|suse/)
      case client_rel
      when /^5/
        client_os = "rhel5"
      else
        client_os = "rhel6"
      end
    end
  end
  if client_arch.match(/64/)
    client_os = client_os+"-64"
  else
    if !client_arch.match(/i386/) and !client_arch.match(/64/)
      client_os = client_os+"-64"
    end
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

# Check VMware Fusion is installed

def check_fusion_is_installed()
  app_dir = "/Applications/VMware Fusion.app"
  if !File.directory?(app_dir)
    puts "Warning:\tVMware Fusion is not installed"
    exit
  end
end

# check VMware Fusion NAT

def check_fusion_natd()
  check_fusion_is_installed()
  if $default_vm_network.match(/hostonly/)
    check_fusion_hostonly_network()
  end
  return
end

# Unconfigure a VMware Fusion VM

def unconfigure_fusion_vm(client_name)
  check_fusion_is_installed()
  exists = check_fusion_vm_exists(client_name)
  if exists == "yes"
    stop_fusion_vm(client_name)
    fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
    fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
    message          = "Deleting:\tVMware Fusion VM "+client_name
    command          = "'#{$vmrun_bin}' -T fusion deleteVM '#{fusion_vmx_file}'"
    execute_command(message,command)
    vm_dir   = client_name+".vmwarevm"
    message  = "Removing:\tVMware Fusion VM "+client_name+" directory"
    command  = "cd '#{$fusion_dir}' ; rm -rf '#{vm_dir}'"
    execute_command(message,command)
  else
    puts "VMware Fusion VM "+client_name+" does not exist"
  end
  return
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
  check_fusion_is_installed()
  (fusion_vm_dir,fusion_vmx_file,fusion_disk_file) = check_fusion_vm_doesnt_exist(client_name)
  check_dir_exists(fusion_vm_dir)
  create_fusion_vm_vmx_file(client_name,client_mac,client_os,fusion_vmx_file)
  create_fusion_vm_disk(client_name,fusion_vm_dir,fusion_disk_file)
  puts
  puts "Client:     "+client_name+" created with MAC address "+client_mac
  puts
  return
end

