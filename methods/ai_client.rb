
# Clienbt code for AI

# List AI services

def list_ai_clients()
  puts
  puts "Current AI clients:"
  puts
  client_info  = %x[installadm list -p |grep -v '^--' |grep -v '^Service']
  client_info  = client_info.split(/\n/)
  service_name = ""
  client_name  = ""
  client_info.each do |line|
    if line.match(/^[A-z]/)
      service_name=line
    else
      client_name = line
      client_name = client_name.gsub(/^\s+/,"")
      client_name = client_name.gsub(/\s+/," ")
      puts client_name+" [ service = "+service_name+" ] "
    end
  end
  puts
  return
end

# Get a list of valid shells

def get_valid_shells()
  vaild_shells = %x[ls /usr/bin |grep 'sh$' |awk '{print "/usr/bin/" $1 }']
  vaild_shells = vaild_shells.split("\n").join(",")
  return vaild_shells
end

# Make sure user ID is greater than 100

def check_valid_uid(answer)
  correct = 1
  if answer.match(/[A-z]/)
    correct = 0
  else
    if Integer(answer) < 100
      correct = 0
      puts "UID must be greater than 100"
    end
  end
  return correct
end

# Make sure user group is greater than 10

def check_valid_gid(answer)
  correct = 1
  if answer.match(/[A-z]/)
    correct = 0
  else
    if Integer(answer) < 10
      correct = 0
      puts "GID must be greater than 10"
    end
  end
  return correct
end

# Get the user home directory ZFS dataset name

def get_account_home_zfs_dataset()
  account_home_zfs_dataset = "/export/home/"+$q_struct["account_login"].value
  return account_home_zfs_dataset
end

# Get the user home directory mount point

def get_account_home_mountpoint()
  account_home_mountpoint = "/export/home/"+$q_struct["account_login"].value
  return account_home_mountpoint
end

# Import AI manifest
# This is done to change the default manifest so that it doesn't point
# to the Oracle one amongst other things
# Check the structs for settings and more information

def import_ai_manifest(output_file,service_name)
  date_string = get_date_string()
  arch_list   = []
  base_name   = get_service_base_name(service_name)
  if !service_name.match(/i386|sparc/) and !client_arch.match(/i386|sparc/)
    arch_list = ["i386","SPARC"]
  else
    if service_name.match(/i386/)
      arch_list.push("i386")
    else
      if service_name.match(/sparc/)
        arch_list.push("SPARC")
      end
    end
  end
  arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    backup  = $work_dir+"/"+base_name+"_"+lc_arch+"_orig_default.xml."+date_string
    message = "Archiving:\tService configuration for "+base_name+"_"+lc_arch+" to "+backup
    command = "installadm export -n #{base_name}_#{lc_arch} -m orig_default > #{backup}"
    output  = execute_command(message,command)
    message = "Validating:\tService configuration "+output_file
    command = "AIM_MANIFEST=#{output_file} ; export AIM_MANIFEST ; aimanifest validate"
    output  = execute_command(message,command)
    if output.match(/[A-z|0-9]/)
      puts "AI manifest file "+output_file+" does not contain a valid XML manifest"
      puts output
    else
      message = "Importing:\t"+output_file+" to service "+service_name+" as manifest named "+$default_manifest_name
      command = "installadm create-manifest -n #{base_name}_#{lc_arch} -m #{$default_manifest_name} -f #{output_file}"
      output  = execute_command(message,command)
      message = "Setting:\tDefault manifest for service "+service_name+" to "+$default_manifest_name
      command = "installadm set-service -o default-manifest=#{$default_manifest_name} #{base_name}_#{lc_arch}"
      output  = execute_command(message,command)
    end
  end
  return
end

# Import a profile and associate it with a client

def import_ai_client_profile(output_file,client_name,client_mac,service_name)
  message = "Creating:\tProfile for client "+client_name+" with MAC address "+client_mac
  command = "installadm create-profile -n #{service_name} -f #{output_file} -p #{client_name} -c mac='#{client_mac}'"
  execute_command(message,command)
  return
end

# Code to change timeout and default menu entry in grub

def update_ai_client_grub_cfg(client_mac)
  copy        = []
  netboot_mac = client_mac.gsub(/:/,"")
  netboot_mac = "01"+netboot_mac
  netboot_mac = netboot_mac.upcase
  grub_file   = $tftp_dir+"/grub.cfg."+netboot_mac
  if $verbose_mode == 1
    puts "Updating:\tGrub config file "+grub_file
  end
  if File.exists?(grub_file)
    text=File.read(grub_file)
    text.each do |line|
      if line.match(/set timeout=30/)
        copy.push("set timeout=5")
        copy.push("set default=1")
      else
        copy.push(line)
      end
    end
    File.open(grub_file,"w") {|file| file.puts copy}
    print_contents_of_file(grub_file)
  end
end

# Main code to configure AI client services
# Called from main code

def configure_ai_client_services(client_arch,publisher_host,publisher_port,service_name)
  puts
  puts "You will be presented with a set of questions followed by the default output"
  puts "If you are happy with the default output simply hit enter"
  puts
  service_list = []
  # Populate questions for AI manifest
  populate_ai_manifest_questions(publisher_host,publisher_port)
  # Process questions
  process_questions(service_name)
  # Set name of AI manifest file to create and import
  if service_name.match(/i386|sparc/)
    service_list[0] = service_name
  else
    service_list[0] = service_name+"_i386"
    service_list[1] = service_name+"_sparc"
  end
  service_list.each do |temp_name|
    output_file = $work_dir+"/"+temp_name+"_ai_manifest.xml"
    # Create manifest
    create_ai_manifest(output_file)
    # Import AI manifest
    import_ai_manifest(output_file,temp_name)
  end
  return
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def update_ai_client_dhcpd_entry(client_name,client_mac,client_ip)
  copy        = []
  client_mac  = client_mac.gsub(/:/,"")
  client_mac  = client_mac.upcase
  dhcp_file    = "/etc/inet/dhcpd4.conf"
  backup_file(dhcp_file)
  text        = File.read(dhcp_file)
  text.each do |line|
    if line.match(/^host #{client_mac}/)
      copy.push("host #{client_name} {")
      copy.push("  fixed-address #{client_ip};")
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file,"w") {|file| file.puts copy}
  print_contents_of_file(dhcp_file)
  return
end

# Routine to actually add a client

def create_ai_client(client_name,client_arch,client_mac,service_name,client_ip)
  message = "Creating:\tClient entry for #{client_name} with architecture #{client_arch} and MAC address #{client_mac}"
  command = "installadm create-client -n #{service_name} -e #{client_mac}"
   execute_command(message,command)
  if client_arch.match(/i386/) or client_arch.match(/i386/)
    update_ai_client_dhcpd_entry(client_name,client_mac,client_ip)
    update_ai_client_grub_cfg(client_mac)
  else
   add_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  end
  smf_service = "svc:/network/dhcp/server:ipv4"
  refresh_smf_service(smf_service)
  return
end

# Check AI client doesn't exist

def check_ai_client_doesnt_exist(client_name,client_mac,service_name)
  client_mac = client_mac.upcase
  message    = "Checking:\tClient "+client_name+" doesn't exist"
  command    = "installadm list -p |grep '#{client_mac}'"
  output     = execute_command(message,command)
  if output.match(/#{client_name}/)
    puts "Warning:\tProfile already exists for "+client_name
    if $yes_to_all == 1
      puts "Deleting:\rtClient "+client_name
      unconfigure_ai_client(client_name,client_mac,service_name)
    else
      exit
    end
  end
  return
end

# Main code to actually add a client

def configure_ai_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name,image_name)
  # Populate questions for AI profile
  if !service_name.match(/i386|sparc/)
    service_name = service_name+"_"+client_arch
  end
  check_ai_client_doesnt_exist(client_name,client_mac,service_name)
  populate_ai_client_profile_questions(client_ip,client_name)
  process_questions(service_name)
  if $os_name.match(/Darwin/)
    tftp_version_dir = $tftp_dir+"/"+service_name
    check_osx_iso_mount(tftp_version_dir,iso_file)
  end
  output_file = $work_dir+"/"+client_name+"_ai_profile.xml"
  create_ai_client_profile(output_file)
  puts "Configuring:\tClient "+client_name+" with MAC address "+client_mac
  import_ai_client_profile(output_file,client_name,client_mac,service_name)
  create_ai_client(client_name,client_arch,client_mac,service_name,client_ip)
  if $os_name.match(/SunOS/) and $os_rel.match(/11/)
    clear_solaris_dhcpd()
  end
  return
end

# Unconfigure  AI client

def unconfigure_ai_client(client_name,client_mac,service_name)
  if !client_mac.match(/[A-z|0-9]/) or !service_name.match(/[A-z|0-9]/)
    repo_list         = %x[installadm list -p |grep -v '^-' |grep -v '^Service']
    temp_client_name  = ""
    temp_client_mac   = ""
    temp_service_name = ""
    repo_list.each do |line|
      line = line.chomp
      if line.match(/[A-z|0-9]/)
        if line.match(/^[A-z|0-9]/)
          line = line.gsub(/\s+/,"")
          temp_service_name = line
        else
          line = line.gsub(/\s+/,"")
          if line.match(/mac=/)
            (temp_client_name,temp_client_mac) = line.split(/mac=/)
            if temp_client_name.match(/^#{client_name}/)
              if !service_name.match(/[A-z|0-9]/)
                service_name = temp_service_name
              end
              if !client_mac.match(/[A-z|0-9]/)
                client_mac = temp_client_mac
              end
            end
          end
        end
      end
    end
  end
  if client_name.match(/[A-z]/) and service_name.match(/[A-z]/) and client_mac.match(/[A-z]/)
    message = "Deleting:\tClient profile "+client_name+" from "+service_name
    command = "installadm delete-profile -p #{client_name} -n #{service_name}"
    execute_command(message,command)
    message = "Deleting:\tClient "+client_name+" with MAC address "+client_mac
    command = "installadm delete-client "+client_mac
    execute_command(message,command)
  else
    puts "Warning:\tClient "+client_name+" does not exist"
    exit
  end
  return
end
