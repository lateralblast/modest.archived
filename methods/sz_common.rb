
# Solaris Zones support code

# List zone services

def list_zone_services()
  os_version = $os_rel.split(/\./)[1]
  os_branded = os_version.to_i-1
  os_branded = os_branded.to_s
  puts "Supported containers:"
  puts
  puts "Solaris "+os_version+" (native)"
  puts "Solaris "+os_branded+" (branded)"
  return
end

def get_zone_image_info(image_file)
  image_info    = image_file.split(/\-/)
  image_os      = image_info[0].split(//)[0..2].join
  image_version = image_info[1].gsub(/u/,".")
  image_arch    = image_info[2]
  if image_arch.match(/x86/)
    image_arch = "i386"
  end
  service_name = image_os+"_"+image_version.gsub(/\./,"_")+"_"+image_arch
  return image_version,image_arch,service_name
end

# List zone ISOs/Images

def list_zone_isos()
  puts "Available branded zone images:"
  puts
  iso_list = Dir.entries($iso_base_dir)
  if $os_arch.match(/sparc/)
    search_arch = $os_arch
  else
    search_arch = "x86"
  end
  iso_list.each do |image_file|
    image_file = image_file.chomp
    if image_file.match(/^solaris/) and image_file.match(/bin$/)
      if image_file.match(/#{search_arch}/)
        (image_version,image_arch,service_name) = get_zone_image_info(image_file)
        puts "Image file:\t"+$iso_base_dir+"/"+image_file
        puts "Distribution:\tSolaris"
        puts "Version:\t"+image_version
        puts "Architecture:\t"+image_arch
        puts "Service Name\t"+service_name
        puts
      end
    end
  end
  return
end

# List available zones

def list_zones()
  puts "Available Zones:"
  puts
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(message,command)
  puts output
  return
end

# Print branded zone information

def print_branded_zone_info()
  branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
  branded_dir = "/export/isos"
  puts "Warning:\tBranded zone templates not found"
  puts "Information:\tDownload them from "+branded_url
  puts "Information:\tCopy them to "+branded_dir
  puts
  return
end

# Check branded zone support is installed

def check_branded_zone_pkg()
  if $os_rel.match(/11/)
    message = "Checking:\tBranded zone support is installed"
    command = "pkg info pkg:/system/zones/brand/brand-solaris10 |grep Version |awk '{print $2}'"
    output  = execute_command(message,command)
    if !output.match(/[0-9]/)
      message = "Installing:\tBranded zone packages"
      command = "pkg install pkg:/system/zones/brand/brand-solaris10"
      execute_command(message,command)
    end
  end
  return
end

# Standard zone post install

def standard_zone_post_install(client_name,client_rel)
  zone_dir = $zone_base_dir+"/"+client_name
  if File.directory?(zone_dir)
    client_dir    = zone_dir+"/root"
    tmp_file      = "/tmp/zone_"+client_name
    admin_username = $q_struct["admin_login"].value
    admin_uid      = $q_struct["admin_uid"].value
    admin_gid      = $q_struct["admin_gid"].value
    admin_crypt    = $q_struct["admin_crypt"].value
    root_crypt    = $q_struct["root_crypt"].value
    admin_fullname = $q_struct["admin_description"].value
    admin_home     = $q_struct["admin_home"].value
    admin_shell    = $q_struct["admin_shell"].value
    passwd_file   = client_dir+"/etc/passwd"
    shadow_file   = client_dir+"/etc/shadow"
    message = "Checking:\tUser "+admin_username+" doesn't exist"
    command = "cat #{passwd_file} | grep -v '#{admin_username}' > #{tmp_file}"
    execute_command(message,command)
    message   = "Adding:\tUser "+admin_username+" to "+passwd_file
    admin_info = admin_username+":x:"+admin_uid+":"+admin_gid+":"+admin_fullname+":"+admin_home+":"+admin_shell
    command = "echo '#{admin_info}' >> #{tmp_file} ; cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(passwd_file)
    info = IO.readlines(shadow_file)
    file = File.open(tmp_file,"w")
    info.each do |line|
      field = line.split(":")
      if field[0] != "root" and field[0] != "#{admin_username}"
        file.write(line)
      end
      if field[0] == "root"
        field[1] = root_crypt
        copy = field.join(":")
        file.write(copy)
      end
    end
    output = admin_username+":"+admin_crypt+":::99999:7:::\n"
    file.write(output)
    file.close
    message = "Creating:\tShadow file"
    command = "cat #{tmp_file} > #{shadow_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(shadow_file)
    client_home = client_dir+admin_home
    message = "Creating:\tSSH directory for "+admin_username
    command = "mkdir -p #{client_home}/.ssh ; cd #{client_dir}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(message,command)
    # Copy admin user keys
    rsa_file = admin_home+"/.ssh/id_rsa.pub"
    dsa_file = admin_home+"/.ssh/id_dsa.pub"
    key_file = client_home+"/.ssh/authorized_keys"
    if File.exists?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file,dsa_file].each do |pub_file|
      if File.exists?(pub_file)
        message = "Copying:\tSSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(message,command)
      end
    end
    message = "Creating:\tSSH directory for root"
    command = "mkdir -p #{client_dir}/root/.ssh ; cd #{client_dir} ; chown -R 0:0 root"
    execute_command(message,command)
    # Copy root keys
    rsa_file = "/root/.ssh/id_rsa.pub"
    dsa_file = "/root/.ssh/id_dsa.pub"
    key_file = client_dir+"/root/.ssh/authorized_keys"
    if File.exists?(key_file)
      system("rm #{key_file}")
    end
    [rsa_file,dsa_file].each do |pub_file|
      if File.exists?(pub_file)
        message = "Copying:\tSSH public key "+pub_file+" to "+key_file
        command = "cat #{pub_file} >> #{key_file}"
        execute_command(message,command)
      end
    end
    # Fix permissions
    message = "Fixing:\t\tSSH permissions for "+admin_username
    command = "cd #{client_dir}/export/home ; chown -R #{admin_uid}:#{admin_gid} #{admin_username}"
    execute_command(message,command)
    message = "Fixing:\t\tSSH permissions for root "
    command = "cd #{client_dir} ; chown -R 0:0 root"
    execute_command(message,command)
    # Add sudoers entry
    sudoers_file = client_dir+"/etc/sudoers"
    message = "Creating:\tSudoers file "+sudoers_file
    command = "cat #{sudoers_file} |grep -v '^#includedir' > #{tmp_file} ; cat #{tmp_file} > #{sudoers_file}"
    execute_command(message,command)
    message = "Adding:\t\tSudoers include to "+sudoers_file
    command = "echo '#includedir /etc/sudoers.d' >> #{sudoers_file} ; rm #{tmp_file}"
    execute_command(message,command)
    sudoers_dir  = client_dir+"/etc/sudoers.d"
    check_dir_exists(sudoers_dir)
    sudoers_file = sudoers_dir+"/"+admin_username
    message = "Creating:\tSudoers file "+sudoers_file
    command = "echo '#{admin_username} ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
    execute_command(message,command)
  else
    puts "Warning:\tZone "+client_name+" doesn't exist"
    exit
  end
  return
end

# Branded zone post install

def branded_zone_post_install(client_name,client_rel)
  zone_dir = $zone_base_dir+"/"+client_name
  if File.directory?(zone_dir)
    client_dir = zone_dir+"/root"
    var_dir    = "/var/tmp"
    tmp_dir    = client_dir+"/"+var_dir
    post_file  = tmp_dir+"/postinstall.sh"
    tmp_file   = "/tmp/zone_"+client_name
    pkg_name   = "pkgutil.pkg"
    pkg_url    = $local_opencsw_mirror+"/"+pkg_name
    pkg_file   = tmp_dir+"/"+pkg_name
    wget_file(pkg_url,pkg_file)
    file = File.open(tmp_file,"w")
    file.write("#!/usr/bin/bash\n")
    file.write("\n")
    file.write("# Post install script\n")
    file.write("\n")
    file.write("cd #{var_dir} ; echo y |pkgadd -d pkgutil.pkg CSWpkgutil\n")
    file.write("export PATH=/opt/csw/bin:$PATH\n")
    file.write("pkutil -i CSWwget\n")
    file.write("\n")
    file.close
    message = "Creating:\tPost install script "+post_file
    command = "cp #{tmp_file} #{post_file} ; rm #{tmp_file}"
    execute_command(message,command)
  else
    puts "Warning:\tZone "+client_name+" doesn't exist"
    exit
  end
  return
end

# Create branded zone

def create_branded_zone(image_file,client_ip,zone_nic,client_name,client_rel)
  check_branded_zone_pkg()
  if Files.exists?(image_file)
    message = "Installing:\tBranded zone "+client_name
    command = "cd /tmp ; #{image_file} -p #{$zone_base_dir} -i #{zone_nic} -z #{client_name} -f"
    execute_command(message,command)
  else
    puts "Warning:\tImage file "+image_file+" doesn't exist"
  end
  standard_zone_post_install(client_name,client_rel)
  branded_zone_post_install(client_name,client_rel)
  return
end

# Check zone doesn't exist

def check_zone_doesnt_exist(client_name)
  message = "Checking:\tZone "+client_name+" doesn't exist"
  command = "zoneadm list -cv |awk '{print $2}' |grep '#{client_name}'"
  output  = execute_command(message,command)
  return output
end

# Create zone config

def create_zone_config(client_name,client_ip)
  virtual  = 0
  zone_nic = $q_struct["ipv4_interface_name"].value
  gateway  = $q_struct["ipv4_default_route"].value
  zone_nic = zone_nic.split(/\//)[0]
  zone_status = check_zone_doesnt_exist(client_name)
  if !zone_status.match(/#{client_name}/)
    if $os_arch.match(/i386/)
      message = "Checking:\tPlatform"
      command = "prtdiag -v |grep 'VMware'"
      output  = execute_command(message,command)
      if output.match(/VMware/)
        virtual = 1
      end
    end
    zone_dir = $zone_base_dir+"/"+client_name
    zone_file = "/tmp/zone_"+client_name
    file = File.open(tmp_file,"w")
    file.write("create -b\n")
    file.write("set brand=solaris\n")
    file.write("set zonepath=#{zone_dir}\n")
    file.write("set autoboot=false\n")
    if virtual == 1
      file.write("set ip-type=shared\n")
      file.write("add net\n")
      file.write("set address=#{client_ip}/24\n")
      file.write("set configure-allowed-address=true\n")
      file.write("set physical=#{zone_nic}\n")
      file.write("set defrouter=#{gateway}\n")
    else
      file.write("set ip-type=exclusive\n")
      file.write("add anet\n")
      file.write("set linkname=#{zone_nic}\n")
      file.write("set lower-link=auto\n")
      file.write("set configure-allowed-address=false\n")
      file.write("set mac-address=random\n")
    end
    file.write("end\n")
    file.close
    print_contents_of_file(zone_file)
  end
  return zone_file
end

# Install zone

def install_zone(client_name,zone_filr)
  message = "Creating:\tSolaris "+client_rel+" zone "+client_name+" in "+zone_dir
  command = "zonecfg -z #{client_name} -f #{zone_file}"
  execute_command(message,command)
  message = "Installing:\tZone "+client_name
  command = "zoneadm -z #{client_name} install"
  execute_command(message,command)
  system("rm #{zone_file}")
  return
end

# Create zone

def create_zone(client_name,client_ip,zone_dir,client_rel,image_file,service_name)
  virtual = 0
  message = "Checking:\tPlatform"
  command = "prtdiag -v |grep 'VMware'"
  output  = execute_command(message,command)
  if output.match(/VMware/)
    virtual = 1
  end
  if service_name.match(/[A-z]/)
    image_info    = service_name.split(/_/)
    image_version = image_info[1]+"u"+image_info[2]
    image_arch    = image_info[3]
    if image_arch.match(/i386/)
      image_arch = "x86"
    end
    image_file = "solaris-"+image_version+"-"+image_arch+".bin"
  end
  if $os_rel.match(/11/) and client_rel.match(/10/)
    if $os_arch.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_zfs_fs_exists(branded_dir)
    if !File.exists(branded_file)
      print_branded_zone_info()
    end
    create_branded_zone(image_file,client_ip,zone_nic,client_name,client_rel)
  else
    if !image_file.match(/[A-z]/)
      zone_file = create_zone_config(client_name,client_ip)
      install_zone(client_name,zone_file)
      standard_zone_post_install(client_name,client_rel)
    else
      if !File.exists?(image_file)
        print_branded_zone_info()
      end
      create_zone_config(client_name,client_ip)
      if $os_rel.match(/11/) and virtual == 1
        puts "Warning:\tCan't create branded zones with exclusive IPs in VMware"
        exit
      else
        create_branded_zone(image_file,client_ip,zone_nic,client_name,client_rel)
      end
    end
  end
  if $serial_mode == 1
    boot_zone(client_name)
  end
  add_hosts_entry(client_name,client_ip)
  return
end

# Halt zone

def halt_zone(client_name)
  message = "Halting:\tZone "+client_name
  command = "zoneadm -z #{client_name} halt"
  execute_command(message,command)
  return
end

# Delete zone

def unconfigure_zone(client_name)
  halt_zone(client_name)
  message = "Uninstalling:\tZone "+client_name
  command = "zoneadm -z #{client_name} uninstall -F"
  execute_command(message,command)
  message = "Deleting:\tZone "+client_name+" configuration"
  command = "zonecfg -z #{client_name} delete -F"
  execute_command(message,command)
  if $yes_to_all == 1
    zone_dir = $zone_base_dir+"/"+client_name
    destroy_zfs_fs(zone_dir)
  end
  client_ip = get_client_ip(client_name)
  remove_hosts_entry(client_name,client_ip)
  return
end

# Get zone status

def get_zone_status(client_name)
  message = "Checking:\tZone "+client_name+" isn't running"
  command = "zoneadm list -cv |grep ' #{client_name} ' |awk '{print $3}'"
  output  = execute_command(message,command)
  return output
end

# Boot zone

def boot_zone(client_name)
  message = "Booting:\tZone "+client_name
  command = "zoneadm -z #{client_name} boot"
  execute_command(message,command)
  if $serial_mode == 1
    system("zlogin #{client_name}")
  end
  return
end

# Shutdown zone

def stop_zone(client_name)
  status  = get_zone_status(client_name)
  if !status.match(/running/)
    message = "Stopping:\tZone "+client_name
    command = "zlogin #{client_name} shutdown -y -g0 -i 0"
    execute_command(message,command)
  end
  return
end



# Configure zone

def configure_zone(client_name,client_ip,client_mac,client_arch,client_os,client_rel,publisher_host,image_file,service_name)
  if client_arch.match(/[A-z]/)
    check_same_arch(client_arch)
  end
  if !image_file.match(/[A-z]/) and !service_name.match(/[A-z]/)
    if !client_rel.match(/[0-9]/)
      client_rel = $os_rel
    end
  end
  if client_rel.match(/11/)
    populate_ai_client_profile_questions(client_ip,client_name)
    process_questions(service_name)
  else
    populate_js_client_profile_questions(client_ip,client_name)
    process_questions(service_name)
    if image_file.match(/[A-z]/)
      (client_rel,client_arch,service_name) = get_zone_image_info(image_file)
      check_same_arch(client_arch)
    end
  end

  if !File.directory?($zone_base_dir)
    check_zfs_fs_exists($zone_base_dir)
    message = "Setting:\tMount point for "+$zone_base_dir
    command = "zfs set #{$default_zpool}#{$zone_base_dir} mountpoint=#{$zone_base_dir}"
    execute_command(message,command)
  end
  zone_dir = $zone_base_dir+"/"+client_name
  create_zone(client_name,client_ip,zone_dir,client_rel,image_file,service_name)
  return
end
