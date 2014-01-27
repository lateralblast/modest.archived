
# Jupstart server code

# List available ISOs

def list_js_isos()
  puts "Available Jumpstart ISOs:"
  puts
  search_string = "\\-ga\\-"
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file|
    iso_file    = iso_file.chomp
    iso_info    = File.basename(iso_file)
    iso_info    = iso_info.split(/-/)
    iso_version = iso_info[1..2].join("_")
    iso_arch    = iso_info[4]
    puts "ISO file:\t"+iso_file
    puts "Distribution:\tSolaris"
    puts "Version:\t"+iso_version
    puts "Architecture:\t"+iso_arch
    service_name     = "sol_"+iso_version+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      puts "Service Name:\t"+service_name+" (exists)"
    else
      puts "Service Name:\t"+service_name
    end
    puts
  end
  return
end

# Configure NFS service

def configure_js_nfs_service(service_name,publisher_host)
  repo_version_dir = $repo_base_dir+"/"+service_name
  network_address  = publisher_host.split(/\./)[0..2].join(".")+".0"
  message          = "Enabling:\tNFS share on "+repo_version_dir
  command          = "zfs set sharenfs=on #{$default_zpool}#{repo_version_dir}"
  output           = execute_command(message,command)
  message          = "Setting:\tNFS access rights on "+repo_version_dir
  command          = "zfs set share=name=#{service_name},path=#{repo_version_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{$default_zpool}#{repo_version_dir}"
  output           = execute_command(message,command)
  return
end

# Unconfigure NFS services

def unconfigure_js_nfs_service(service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  message          = "Disabling:\tNFS share on "+repo_version_dir
  command          = "zfs set sharenfs=off #{$default_zpool}#{repo_version_dir}"
  execute_command(message,command)
end

# Configure tftpboot services

def configure_js_tftp_service(client_arch,service_name,repo_version_dir,os_version)
  pkg_name = "system/boot/network"
  message  = "Checking:\tBoot server package is installed"
  command  = "pkg info #{pkg_name} |grep Name |awk '{print $2}'"
  output   = execute_command(message,command)
  if !output.match(/#{pkg_name}/)
    message = "Installing:\tBoot server package"
    command = "pkg install #{pkg_name}"
    output  = execute_command(message,command)
  end
  tftp_dir="/tftpboot"
  netboot_dir="/etc/netboot"
  if !File.symlink?(tftp_dir)
    message = "Symlinking:\tDirectory "+tftp_dir+" to "+netboot_dir
    command = "ln -s #{tftp_dir} #{netboot_dir}"
    output  = execute_command(message,command)
  end
  smf_service_name="svc:/network/tftp/udp6:default"
  message="Checking:\tTFTP service is installed"
  command="svcs -a |grep '#{smf_service_name}'"
  output=execute_command(message,command)
  if !output.match(/#{smf_service_name}/)
    message = "Creating:\tTFTP service information"
    command = "echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
    output  = execute_command(message,command)
    message = "Creating:\tTFTP service manifest"
    command = "inetconv -i /tmp/tftp"
    output  = execute_command(message,command)
  end
  enable_smf_service(smf_service_name)
  boot_dir=netboot_dir+"/"+service_name+"/boot"
  if !File.directory?(boot_dir)
    check_dir_exists(boot_dir)
    source_dir = repo_version_dir+"/boot"
    message    = "Copying:\tBoot files from "+source_dir+" to "+boot_dir
    command    = "cp -r #{source_dir}/* #{boot_dir}"
    output     = execute_command(message,command)
  end
  return
end

# Unconfigure jumpstart tftpboot services

def unconfigure_js_tftp_service()
  return
end

# Copy SPARC boot images to /tftpboot

def copy_js_sparc_boot_images(repo_version_dir,os_version,os_update)
  boot_list=[]
  tftp_dir="/tftpboot"
  boot_list.push("sun4u")
  if os_version == "10"
    boot_list.push("sun4v")
  end
  boot_list.each do |boot_arch|
    boot_file = repo_version_dir+"/Solaris_"+os_version+"/Tools/Boot/platform/"+boot_arch+"/inetboot"
    tftp_file = tftp_dir+"/"+boot_arch+".inetboot.sol_"+os_version+"_"+os_update
    if !File.exists?(boot_file)
      message = "Copying:\tBoot image "+boot_file+" to "+tftp_file
      command = "cp #{boot_file} #{tftp_file}"
      execute_command(message,command)
    end
  end
  return
end

# Unconfigure jumpstart repo

def unconfigure_js_repo(service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  destroy_zfs_fs(repo_version_dir)
  return
end

# Configure Jumpstart repo

def configure_js_repo(iso_file,repo_version_dir,os_version,os_update)
  check_zfs_fs_exists(repo_version_dir)
  check_dir = repo_version_dir+"/boot"
  if $verbose_mode == 1
    puts "Checking:\tDirectory "+check_dir+" exists"
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    check_dir = $iso_mount_dir+"/boot"
    if $verbose_mode == 1
      puts "Checking:\tDirectory "+check_dir+" exists"
    end
    if File.directory?(check_dir)
      iso_update = get_js_iso_update($iso_mount_dir,os_version)
      puts iso_update
      puts os_update
      if !iso_update.match(/#{os_update}/)
        puts "Warning:\tISO update version does not match ISO name"
        exit
      end
      message = "Copying:\tISO file "+iso_file+" contents to "+repo_version_dir
      command = "cd /cdrom/Solaris_#{os_version}/Tools ; ./setup_install_server #{repo_version_dir}"
      execute_command(message,command)
    else
      puts "Warning:\tISO "+iso_file+" is not mounted"
      return
    end
    umount_iso()
  end
  return
end

# Fix rm_install_client script

def fix_js_rm_client(repo_version_dir,os_version)
  file_name   = "rm_install_client"
  rm_script   = repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  backup_file = rm_script+".modest"
  if !File.exists?(backup_file)
    message = "Archiving:\tRemove install script "+rm_script+" to "+backup_file
    command = "cp #{rm_script} #{backup_file}"
    execute_command(message,command)
    text    = File.read(rm_script)
    copy    = []
    text.each do |line|
      if line.match(/ANS/) and line.match(/sed/) and !line.match(/\{/)
        line=line.gsub(/#/,' #')
      end
      if line.match(/nslookup/) and !line.match(/sed/)
        line="ANS=`nslookup ${K} | /bin/sed '/^;;/d' 2>&1`"
      end
      copy.push(line)
    end
    File.open(rm_script,"w") {|file| file.puts copy}
  end
  return
end

# List Jumpstart services

def list_js_services()
  puts "Available Jumpstart services:"
  puts
  service_list=Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/^sol/) and !service_name.match(/sol_11/)
      puts service_name
    end
  end
  return
end

# Fix check script

def fix_js_check(repo_version_dir,os_version)
  file_name    = "check"
  check_script = repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  backup_file  = check_script+".modest"
  if !File.exists?(backup_file)
    message = "Archiving:\tCheck script "+check_script+" to "+backup_file
    command = "cp #{check_script} #{backup_file}"
    execute_command(message,command)
    text    = File.read(check_script)
    copy    = text
    copy[0] = "#!/usr/sbin/sh\n"
    File.open(check_script,"w") {|file| file.puts copy}
  end
  return
end

# Unconfigure jumpstart server

def unconfigure_js_server(service_name)
  unconfigure_js_nfs_service(service_name)
  unconfigure_js_repo(service_name)
  unconfigure_js_tftp_service()
  return
end

# Configure jumpstart server

def configure_js_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  check_dhcpd_config(publisher_host)
  iso_list      = []
  search_string = "\\-ga\\-"
  if iso_file.match(/[A-z]/)
    if File.exists?(iso_file)
      iso_list[0] = iso_file
    else
      puts "Warning:\tISO file "+is_file+" does not exist"
    end
  else
    iso_list=check_iso_base_dir(search_string)
  end
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    iso_info      = File.basename(iso_file_name)
    iso_info      = iso_info.split(/\-/)
    os_version    = iso_info[1]
    os_update     = iso_info[2]
    os_update     = os_update.gsub(/u/,"")
    os_arch       = iso_info[4]
    if !os_arch.match(/sparc/)
      if os_arch.match(/x86/)
        os_arch = "i386"
      else
        puts "Warning:\tCould not determine architecture from ISO name"
        exit
      end
    end
    service_name     = "sol_"+os_version+"_"+os_update+"_"+os_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    add_apache_alias(service_name)
    configure_js_repo(iso_file_name,repo_version_dir,os_version,os_update)
    configure_js_tftp_service(client_arch,service_name,repo_version_dir,os_version)
    configure_js_nfs_service(service_name,publisher_host)
    if os_arch.match(/sparc/)
      copy_js_sparc_boot_images(repo_version_dir,os_version,os_update)
    end
    fix_js_rm_client(repo_version_dir,os_version)
    fix_js_check(repo_version_dir,os_version)
  end
  return
end
