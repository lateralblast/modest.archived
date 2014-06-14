# Server code for *BSD PXE boot

# List available *BSD ISOs

def list_xb_isos()
  search_string = "install|FreeBSD"
  list_bsd_isos(search_string)
  return
end

# Configure BSD server

def configure_xb_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  if service_name.match(/[A-z]/)
    if service_name.downcase.match(/openbsd/)
      search_string = "install"
    end
    if service_name.downcase.match(/freebsd/)
      search_string = "FreeBSD"
    end
  else
    search_string = "install|FreeBSD"
  end
  configure_bsd_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# Copy Linux ISO contents to repo

def configure_xb_repo(iso_file,repo_version_dir)
  check_zfs_fs_exists(repo_version_dir)
  if repo_version_dir.match(/sles/)
    check_dir = repo_version_dir+"/boot"
  else
    check_dir = repo_version_dir+"/isolinux"
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

def configure_xb_pxe_boot(service_name,repo_version_dir)
  pxe_boot_dir = $tftp_dir+"/"+service_name
  if !File.symlink?(pxe_boot_dir)
    File.symlink(repo_version_dir,pxe_boot_dir)
  end
  return
end

# Configue Linux server

def configure_bsd_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  iso_list = []
  check_zfs_fs_exists($client_base_dir)
  check_dhcpd_config(publisher_host)
  if iso_file.match(/[A-z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/install|FreeBSD/)
        puts "Warning:\tISO "+iso_file+" does not appear to be a valid Linux distribution"
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
      (bsd_distro,iso_version,iso_arch) = get_bsd_version_info(iso_file_name)
      iso_version  = iso_version.gsub(/\./,"_")
      service_name = bsd_distro.downcase+"_"+iso_version+"_"+iso_arch
      repo_version_dir  = $repo_base_dir+"/"+service_name
      add_apache_alias(service_name)
      configure_xb_repo(iso_file_name,repo_version_dir)
      configure_xb_pxe_boot(service_name,repo_version_dir)
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
