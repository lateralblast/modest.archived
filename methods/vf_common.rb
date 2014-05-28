# VMware Fusion support code

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

# List Fusion VMs

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

# Create VMware Fusion VM disk

def create_fusion_vm_disk(client_name,fusion_vm_dir,fusion_disk_file)
  if File.exist?(fusion_disk_file)
    puts "Warning:\tVMware Fusion VM disk '"+fusion_disk_file+"' already exists for "+client_name
    exit
  end
  check_dir_exists(fusion_vm_dir)
  vdisk_bin = "/Applications/VMware Fusion.app//Contents/Library/vmware-vdiskmanager"
  message   = "Creating:\tVMware Fusion disk '"+fusion_disk_file+"' for "+client_name
  command   = "cd '#{fusion_vm_dir}' ; '#{vdisk_bin}' -c -s '#{$default_vm_size}' -a LsiLogic -t 1 '#{fusion_disk_file}'"
  execute_command(message,command)
  return
end


# Check VMware Fusion VM exists

def check_fusion_vm_exists(client_name)
  fusion_vm_dir    = $fusion_dir+"/"+client_name+".vmwarevm"
  fusion_vmx_file  = fusion_vm_dir+"/"+client_name+".vmx"
  if !File.exist?(fusion_vmx_file)
    puts "Information:\tVMware Fusion VM "+client_name+" does not exist"
    exit
  end
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
  puts
  puts "Client:     "+client_name+" created with MAC address "+client_mac
  puts
  return
end

