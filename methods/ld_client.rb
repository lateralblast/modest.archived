# Guest Domain support code

# Get Guest domain MAC

def get_gdom_mac(client_name)
  message    = "Getting:\tGuest domain "+client_name+" MAC address"
  command    = "ldm list-bindings #{client_name} |grep '#{$default_gdom_vnet}' |awk '{print $5}'"
  output     = execute_command(message,command)
  client_mac = output.chomp
  return client_mac
end

# List available LDoms

def list_gdoms()
  puts "Available Guest Domains:"
  message   = ""
  command   = "ldm list |grep -v NAME |grep -v primary |awk '{print $1}'"
  output    = execute_command(message,command)
  gdom_list = output.split(/\n/)
  gdom_list.each do |gdom_name|
    gdom_mac = get_gdom_mac(gdom_name)
    puts gdom_name+" "+gdom_mac
  end
  return
end

# Create Guest domain disk

def create_gdom_disk(client_name)
  client_disk = $q_struct["gdom_disk"].value
  disk_size   = $q_struct["gdom_size"].value
  disk_size   = disk_size.downcase
  vds_disk    = client_name+"_vdisk0"
  if !client_disk.match(/\/dev/)
    if !File.exists?(client_disk)
      message = "Creating:\tGuest domain disk "+client_disk+" for client "+client_name
      command = "mkfile -n #{disk_size} #{client_disk}"
      output = execute_command(message,command)
    end
  end
  message = "Checking:\tVirtual Disk Server device doesn't already exist"
  command = "ldm list-services |grep 'primary-vds0' |grep '#{vds_disk}'"
  output = execute_command(message,command)
  if !output.match(/#{client_name}/)
    message = "Adding:\tDisk device to Virtual Disk Server"
    command = "ldm add-vdsdev #{client_disk} #{vds_disk}@primary-vds0"
    output = execute_command(message,command)
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_doesnt_exist(client_name)
  message = "Checking:\tGuest domain "+client_name+" doesn't exist"
  command = "ldm list |grep #{client_name}"
  output  = execute_command(message,command)
  if output.match(/#{client_name}/)
    puts "Warning:\tGuest domain "+client_name+" already exists"
    exit
  end
  return
end

# Check Guest domain doesn't exist

def check_gdom_exists(client_name)
  message = "Checking:\tGuest domain "+client_name+" exist"
  command = "ldm list |grep #{client_name}"
  output  = execute_command(message,command)
  if !output.match(/#{client_name}/)
    puts "Warning:\tGuest domain "+client_name+" doesn't exist"
    exit
  end
  return
end

# Start Guest domain

def start_gdom(client_name)
  message = "Starting:\tGuest domain "+client_name
  command = "ldm start-domain #{client_name}"
  execute_command(message,command)
  return
end

# Stop Guest domain

def stop_gdom(client_name)
  message = "Stopping:\tGuest domain "+client_name
  command = "ldm stop-domain #{client_name}"
  execute_command(message,command)
  return
end

# Bind Guest domain

def bind_gdom(client_name)
  message = "Binding:\tGuest domain "+client_name
  command = "ldm bind-domain #{client_name}"
  execute_command(message,command)
  return
end

# Unbind Guest domain

def unbind_gdom(client_name)
  message = "Binding:\tGuest domain "+client_name
  command = "ldm unbind-domain #{client_name}"
  execute_command(message,command)
  return
end

# Remove Guest domain

def remove_gdom(client_name)
  message = "Removing:\tGuest domain "+client_name
  command = "ldm remove-domain #{client_name}"
  execute_command(message,command)
  return
end

# Remove Guest domain disk

def remove_gdom_disk(client_name)
  vds_disk = client_name+"_vdisk0"
  message = "Removing:\tDisk "+vds_disk+" from Virtual Disk Server"
  command = "ldm remove-vdisk #{vds_disk} #{client_name}"
  execute_command(message,command)
  return
end

# Delete Guest domain disk

def delete_gdom_disk(client_name)
  gdom_dir    = $ldom_base_dir+"/"+client_name
  client_disk = gdom_dir+"/vdisk0"
  message = "Removing:\tDisk "+client_disk
  command = "rm #{client_disk}"
  execute_command(message,command)
  return
end

# Delete Guest domain directory

def delete_gdom_dir(client_name)
  gdom_dir    = $ldom_base_dir+"/"+client_name
  destroy_zfs_fs(gdom_dir)
  return
end

# Create Guest domain

def create_gdom(client_name)
  memory   = $q_struct["gdom_memory"].value
  vcpu     = $q_struct["gdom_vcpu"].value
  vds_disk = client_name+"_vdisk0"
  message = "Creating:\tGuest domain "+client_name
  command = "ldm add-domain #{client_name}"
  execute_command(message,command)
  message = "Adding:\tvCPUs to Guest domain "+client_name
  command = "ldm add-vcpu #{vcpu} #{client_name}"
  execute_command(message,command)
  message = "Adding:\tMemory to Guest domain "+client_name
  command = "ldm add-memory #{memory} #{client_name}"
  execute_command(message,command)
  message = "Adding:\tNetwork to Guest domain "+client_name
  command = "ldm add-vnet #{$default_gdom_vnet} primary-vsw0 #{client_name}"
  execute_command(message,command)
  message = "Adding:\tDisk to Guest domain "+client_name
  command = "ldm add-vdisk vdisk0 #{vds_disk}@primary-vds0 #{client_name}"
  execute_command(message,command)
  return
end

# Configure Guest domain

def configure_gdom(client_name,client_ip,client_mac,client_arch,client_os,client_rel,publisher_host)
  service_name = ""
  check_gdom_doesnt_exist(client_name)
  if !File.directory?($ldom_base_dir)
    check_zfs_fs_exists($ldom_base_dir)
    message = "Setting:\tMount point for "+$ldom_base_dir
    command = "zfs set #{$default_zpool}#{$ldom_base_dir} mountpoint=#{$ldom_base_dir}"
    execute_command(message,command)
  end
  gdom_dir = $ldom_base_dir+"/"+client_name
  if !File.directory?(gdom_dir)
    check_zfs_fs_exists(gdom_dir)
    message = "Setting:\tMount point for "+gdom_dir
    command = "zfs set #{$default_zpool}#{gdom_dir} mountpoint=#{gdom_dir}"
    execute_command(message,command)
  end
  populate_gdom_questions(client_name)
  process_questions(service_name)
  create_gdom_disk(client_name)
  create_gdom(client_name)
  bind_gdom(client_name)
  return
end

# Unconfigure Guest domain

def unconfigure_gdom(client_name)
  check_gdom_exists(client_name)
  stop_gdom(client_name)
  unbind_gdom(client_name)
  remove_gdom_disk(client_name)
  remove_gdom(client_name)
  delete_gdom_disk(client_name)
  delete_gdom_dir(client_name)
  return
end
