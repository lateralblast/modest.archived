# Server code for *BSD and other (e.g. CoreOS) PXE boot

# List available *BSD ISOs

def list_xb_isos()
  search_string = "install|FreeBSD|coreos"
  list_other_isos(search_string)
  return
end

# Configure BSD server

def configure_xb_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  if service_name.match(/[A-z]/)
    case service_name
    when /openbsd/
      search_string = "install"
    when /freebsd/
      search_string = "FreeBSD"
    when /coreos/
      search_string = "coreos"
    end
  else
    search_string = "install|FreeBSD|coreos"
  end
  configure_other_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# Copy Linux ISO contents to repo

def configure_xb_repo(iso_file,repo_version_dir,service_name)
  check_zfs_fs_exists(repo_version_dir)
  case service_name
  when /openbsd|freebsd/
    check_dir = repo_version_dir+"/etc"
  when /coreos/
    check_dir = repo_version_dir+"/coreos"
  end
  if $verbose_mode == 1
    puts "Checking:\tDirectory "+check_dir+" exits"
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    copy_iso(iso_file,repo_version_dir)
    umount_iso()
  end
  return
end

# Configure PXE boot

def configure_xb_pxe_boot(iso_arch,iso_version,service_name,pxe_boot_dir,repo_version_dir)
  if service_name.match(/openbsd/)
    iso_arch = iso_arch.gsub(/x86_64/,"amd64")
    pxe_boot_file = pxe_boot_dir+"/"+iso_version+"/"+iso_arch+"/pxeboot"
    if !File.exist?(pxe_boot_file)
      pxe_boot_url = $openbsd_base_url+"/"+iso_version+"/"+iso_arch+"/pxeboot"
      wget_file(pxe_boot_url,pxe_boot_file)
    end
  end
  return
end

# Unconfigure BSD server

def unconfigure_xb_server(service_name)
  remove_apache_alias(service_name)
  pxe_boot_dir     = $tftp_dir+"/"+service_name
  repo_version_dir = $repo_base_dir+"/"+service_name
  destroy_zfs_fs(repo_version_dir)
  if File.symlink?(repo_version_dir)
    File.delete(repo_version_dir)
  end
  if File.directory?(pxe_boot_dir)
    Dir.rmdir(pxe_boot_dir)
  end
  return
end

# Configue BSD server

def configure_other_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  iso_list = []
  check_dhcpd_config(publisher_host)
  if iso_file.match(/[A-z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/install|FreeBSD|coreos/)
        puts "Warning:\tISO "+iso_file+" does not appear to be a valid distribution"
        exit
      else
        iso_list[0] = iso_file
      end
    else
      puts "Warning:\tISO file "+iso_file+" does not exist"
    end
  else
    iso_list = check_iso_base_dir(search_string)
  end
  if iso_list[0]
    iso_list.each do |iso_file_name|
      iso_file_name = iso_file_name.chomp
      (other_distro,iso_version,iso_arch) = get_other_version_info(iso_file_name)
      service_name = other_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
      pxe_boot_dir = $tftp_dir+"/"+service_name
      repo_version_dir  = $repo_base_dir+"/"+service_name
      add_apache_alias(service_name)
      configure_xb_repo(iso_file_name,repo_version_dir,service_name)
      configure_xb_pxe_boot(iso_arch,iso_version,service_name,pxe_boot_dir,repo_version_dir)
    end
  else
    if service_name.match(/[A-z]/)
      if !client_arch.match(/[A-z]/)
        iso_info    = service_name.split(/_/)
        client_arch = iso_info[-1]
      end
      add_apache_alias(service_name)
      configure_xb_pxe_boot(service_name,client_arch)
    else
      puts "Warning:\tISO file and/or Service name not found"
      exit
    end
  end
  return
end

# List kickstart services

def list_xb_services()
  puts
  puts "BSD services:"
  puts
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/bsd|coreos/)
      puts service_name
    end
  end
  puts
  return
end
