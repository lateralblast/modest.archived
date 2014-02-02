
# Server code for VSphere

# List available ISOs

def list_vs_isos()
  puts "Available vSphere ISOs:"
  puts
  search_string = "VMvisor"
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file|
    iso_file    = iso_file.chomp
    iso_info    = File.basename(iso_file)
    iso_info    = iso_info.split(/-/)
    vs_distro   = iso_info[0]
    vs_distro   = vs_distro.downcase
    iso_version = iso_info[3]
    iso_arch    = iso_info[4].split(/\./)[1]
    iso_release = iso_info[4].split(/\./)[0]
    puts "ISO file:\t"+iso_file
    puts "Distribution:\t"+vs_distro
    puts "Version:\t"+iso_version
    puts "Release:\t"+iso_release
    puts "Architecture:\t"+iso_arch
    iso_version      = iso_version.gsub(/\./,"_")
    service_name     = vs_distro+"_"+iso_version+"_"+iso_arch
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

# Unconfigure alternate packages

def unconfigure_vs_alt_repo(service_name)
  return
end

# Configure alternate packages

def configure_vs_alt_repo(service_name,client_arch)
  rpm_list = build_vs_alt_rpm_list(service_name)
  alt_dir  = $repo_base_dir+"/"+service_name+"/alt"
  check_dir_exists(alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if !File.exists?(rpm_file)
      wget_file(rpm_url,rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_vs_repo(service_name)
  remove_apache_alias(service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  destroy_zfs_fs(repo_version_dir)
  if File.symlink?(repo_version_dir)
    message = "Removing:\tSymlink "+repo_version_dir
    command = "rm #{repo_version_dir}"
    execute_command(message,command)
  end
  netboot_repo_dir = $tftp_dir+"/"+service_name
  if File.directory?(netboot_repo_dir)
    message = "Removing:\tDirectory "+netboot_repo_dir
    command = "rmdir #{netboot_repo_dir}"
    execute_command(message,command)
  end
  return
end

# Copy Linux ISO contents to

def configure_vs_repo(iso_file,repo_version_dir,service_name)
  check_zfs_fs_exists(repo_version_dir)
  check_dir = repo_version_dir+"/upgrade"
  if $verbose_mode == 1
    puts "Checking:\tDirectory "+check_dir+" exists"
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    repo_version_dir = $tftp_dir+"/"+service_name
    copy_iso(iso_file,repo_version_dir)
    umount_iso()
  end
  return
end

# Unconfigure VSphere server

def unconfigure_vs_server(service_name)
  unconfigure_vs_repo(service_name)
end

# Configure PXE boot

def configure_vs_pxe_boot(service_name)
  pxe_boot_dir = $tftp_dir+"/"+service_name
  test_dir     = pxe_boot_dir+"/usr"
  if !File.directory?(test_dir)
    rpm_dir = $work_dir+"/rpms"
    check_dir_exists(rpm_dir)
    if File.directory?(rpm_dir)
      message  = "Locating:\tSyslinux package"
      command  = "ls #{rpm_dir} |grep 'syslinux-[0-9]'"
      output   = execute_command(message,command)
      rpm_file = output.chomp
      if !rpm_file.match(/syslinux/)
        rpm_file = "syslinux-4.02-7.2.el5.i386.rpm"
        rpm_file = rpm_dir+"/"+rpm_file
        rpm_url  = "http://mirror.centos.org/centos/5/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
        wget_file(rpm_url,rpm_file)
      else
        rpm_file = rpm_dir+"/"+rpm_file
      end
      check_dir_exists(pxe_boot_dir)
      message = "Copying:\tPXE boot files from "+rpm_file+" to "+pxe_boot_dir
      command = "cd #{pxe_boot_dir} ; #{$rpm2cpio_bin} #{rpm_file} | cpio -iud"
      output  = execute_command(message,command)
    else
      puts "Warning:\tSource directory "+rpm_dir+" does not exist"
      exit
    end
  end
  if !service_name.match(/vmware/)
    pxe_image_dir=pxe_boot_dir+"/images"
    if !File.directory?(pxe_image_dir)
      iso_image_dir = $repo_base_dir+"/"+service_name+"/images"
      message       = "Copying:\tPXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{pxe_boot_dir}"
      output        = execute_command(message,command)
    end
  end
  pxe_cfg_dir = $tftp_dir+"/pxelinux.cfg"
  check_dir_exists(pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_vs_pxe_boot(service_name)
  return
end

# Configure VSphere server

def configure_vs_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  search_string = "VMvisor"
  iso_list      = []
  if iso_file.match(/[A-z]/)
    if File.exists?(iso_file)
      if !iso_file.match(/VM/)
        puts "Warning:\tISO "+iso_file+" does not appear to be VMware distribution"
        exit
      else
        iso_list[0] = iso_file
      end
    else
      puts "Warning:\tISO file "+is_file+" does not exist"
    end
  else
    iso_list = check_iso_base_dir(search_string)
  end
  if iso_list[0]
    iso_list.each do |iso_file_name|
      iso_file_name    = iso_file_name.chomp
      iso_info         = File.basename(iso_file_name)
      iso_info         = iso_info.split(/-/)
      vs_distro        = iso_info[0]
      vs_distro        = vs_distro.downcase
      iso_version      = iso_info[3]
      iso_arch         = iso_info[4].split(/\./)[1]
      iso_version      = iso_version.gsub(/\./,"_")
      service_name     = vs_distro+"_"+iso_version+"_"+iso_arch
      repo_version_dir = $repo_base_dir+"/"+service_name
      add_apache_alias(service_name)
      configure_vs_repo(iso_file_name,repo_version_dir,service_name)
      configure_vs_pxe_boot(service_name)
    end
  else
    add_apache_alias(service_name)
    configure_vs_repo(iso_file,repo_version_dir)
    configure_vs_pxe_boot(service_name)
  end
  return
end

# List kickstart services

def list_vs_services()
  puts "VSphere services:"
  puts
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/vmware/)
      puts service_name
    end
  end
  return
end
