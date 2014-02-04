
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
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      check_zfs_fs_exists($client_base_dir)
      add_nfs_export(service_name,repo_version_dir,publisher_host)
      export_name = "client_configs"
      add_nfs_export(export_name,$client_base_dir,publisher_host)
    else
      check_dir_exists($client_base_dir)
      add_nfs_export(service_name,repo_version_dir,publisher_host)
      export_name = "client_configs"
      add_nfs_export(export_name,$client_base_dir,publisher_host)
    end
  else
    check_dir_exists($client_base_dir)
    add_nfs_export(service_name,repo_version_dir,publisher_host)
    export_name = "client_configs"
    add_nfs_export(export_name,$client_base_dir,publisher_host)
  end
  return
end

# Unconfigure NFS services

def unconfigure_js_nfs_service(service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  remove_nfs_export(repo_version_dir)
end

# Configure tftpboot services

def configure_js_tftp_service(client_arch,service_name,repo_version_dir,os_version)
  boot_dir=$tftp_dir+"/"+service_name+"/boot"
  source_dir = repo_version_dir+"/boot"
  if $os_name.match(/SunOS/)
    if $os_rel.match(/11/)
      pkg_name = "system/boot/network"
      message  = "Checking:\tBoot server package is installed"
      command  = "pkg info #{pkg_name} |grep Name |awk '{print $2}'"
      output   = execute_command(message,command)
      if !output.match(/#{pkg_name}/)
        message = "Installing:\tBoot server package"
        command = "pkg install #{pkg_name}"
        output  = execute_command(message,command)
      end
      old_tftp_dir="/tftpboot"
      if !File.symlink?(tftp_dir)
        message = "Symlinking:\tDirectory "+old_tftp_dir+" to "+$tftp_dir
        command = "ln -s #{old_tftp_dir} #{$tftp_dir}"
        output  = execute_command(message,command)
      end
      smf_service_name="svc:/network/tftp/udp6:default"
      message = "Checking:\tTFTP service is installed"
      command = "svcs -a |grep '#{smf_service_name}'"
      output  = execute_command(message,command)
      if !output.match(/#{smf_service_name}/)
        message = "Creating:\tTFTP service information"
        command = "echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
        output  = execute_command(message,command)
        message = "Creating:\tTFTP service manifest"
        command = "inetconv -i /tmp/tftp"
        output  = execute_command(message,command)
      end
      enable_smf_service(smf_service_name)
    end
  end
  if $os_name.match(/Darwin/)
    check_osx_tftpd()
  end
  if $os_name.match(/Linux/)
  end
  if !File.directory?(boot_dir)
    check_dir_exists(boot_dir)
    message = "Copying:\tBoot files from "+source_dir+" to "+boot_dir
    command = "cp -r #{source_dir}/* #{boot_dir}"
    output  = execute_command(message,command)
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
    if !File.exist?(boot_file)
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
  if $os_name.match(/SunOS|Linux/)
    check_zfs_fs_exists(repo_version_dir)
  else
    check_dir_exists(repo_version_dir)
  end
  check_dir = repo_version_dir+"/boot"
  if $verbose_mode == 1
    puts "Checking:\tDirectory "+check_dir+" exists"
  end
  if !File.directory?(check_dir)
    if $os_name.match(/SunOS/)
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
        if $os_name.match(/SunOS/)
          command = "cd /cdrom/Solaris_#{os_version}/Tools ; ./setup_install_server #{repo_version_dir}"
        else
          command = "(cd /cdrom ; tar -cpf - . ) | (cd #{repo_version_dir} ; tar -xpf - )"
        end
        execute_command(message,command)
      else
        puts "Warning:\tISO "+iso_file+" is not mounted"
        return
      end
      umount_iso()
    else
      if !File.directory?(check_dir)
        check_osx_iso_mount(repo_version_dir,iso_file)
      end
    end
  end
  return
end

# Fix rm_install_client script

def fix_js_rm_client(repo_version_dir,os_version)
  file_name   = "rm_install_client"
  rm_script   = repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  backup_file = rm_script+".modest"
  if !File.exist?(backup_file)
    message = "Archiving:\tRemove install script "+rm_script+" to "+backup_file
    command = "cp #{rm_script} #{backup_file}"
    execute_command(message,command)
    text = File.read(rm_script)
    copy = []
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
  if !File.exist?(backup_file)
    message = "Archiving:\tCheck script "+check_script+" to "+backup_file
    command = "cp #{check_script} #{backup_file}"
    execute_command(message,command)
    text     = File.read(check_script)
    copy     = text
    copy[0]  = "#!/usr/sbin/sh\n"
    tmp_file = "/tmp/check_script"
    File.open(tmp_file,"w") {|file| file.puts copy}
    message  = "Updating:\tCheck script"
    command  = "cp #{tmp_file} #{check_script} ; chmod +x #{check_script} ; rm #{tmp_file}"
    execute_command(message,command)
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
    if File.exist?(iso_file)
      if !iso_file.match(/sol/)
        puts "Warning:\tISO "+iso_file+" does not appear to be a valid Solaris distribution"
        exit
      else
        iso_list[0] = iso_file
      end
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
    if !$os_name.match(/Darwin/)
      fix_js_rm_client(repo_version_dir,os_version)
      fix_js_check(repo_version_dir,os_version)
    else
      tune_osx_nfs()
    end
  end
  return
end
