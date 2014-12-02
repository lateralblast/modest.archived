
# Server code for Kickstart

# List available Kiskstart ISOs

def list_ks_isos()
  search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  list_linux_isos(search_string)
  return
end

# Unconfigure alternate packages

def unconfigure_ks_alt_repo(service_name)
  return
end

# Configure alternate packages

def configure_ks_alt_repo(service_name,client_arch)
  rpm_list = build_ks_alt_rpm_list(service_name)
  alt_dir  = $repo_base_dir+"/"+service_name+"/alt"
  check_dir_exists(alt_dir)
  rpm_list.each do |rpm_url|
    rpm_file = File.basename(rpm_url)
    rpm_file = alt_dir+"/"+rpm_file
    if !File.exist?(rpm_file)
      wget_file(rpm_url,rpm_file)
    end
  end
  return
end

# Unconfigure Linux repo

def unconfigure_ks_repo(service_name)
  remove_apache_alias(service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  destroy_zfs_fs(repo_version_dir)
  return
end

# Copy Linux ISO contents to repo

def configure_ks_repo(iso_file,repo_version_dir)
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
    if iso_file.match(/DVD1\.iso|1of2\.iso/)
      if iso_file.match(/DVD1/)
        iso_file = iso_file.gsub(/1\.iso/,"2.iso")
      end
      if iso_file.match(/1of2/)
        iso_file = iso_file.gsub(/1of2\.iso/,"2of2.iso")
      end
      mount_iso(iso_file)
      copy_iso(iso_file,repo_version_dir)
      umount_iso()
    end
  end
  return
end

# Unconfigure Kickstart server

def unconfigure_ks_server(service_name)
  unconfigure_ks_repo(service_name)
end

# Configure PXE boot

def configure_ks_pxe_boot(service_name,iso_arch)
  pxe_boot_dir = $tftp_dir+"/"+service_name
  if service_name.match(/centos|rhel|fedora|sles|sl_|oel/)
    test_dir     = pxe_boot_dir+"/usr"
    if !File.directory?(test_dir)
      if service_name.match(/centos/)
        rpm_dir = $repo_base_dir+"/"+service_name+"/CentOS"
        if !File.directory?(rpm_dir)
          rpm_dir = $repo_base_dir+"/"+service_name+"/Packages"
        end
      end
      if service_name.match(/sles/)
        rpm_dir = $repo_base_dir+"/"+service_name+"/suse"
      end
      if service_name.match(/sl_/)
        rpm_dir = $repo_base_dir+"/"+service_name+"/Scientific"
        if !File.directory?(rpm_dir)
          rpm_dir = $repo_base_dir+"/"+service_name+"/Packages"
        end
      end
      if service_name.match(/oel|rhel|fedora/)
        rpm_dir = $repo_base_dir+"/"+service_name+"/Packages"
      end
      if File.directory?(rpm_dir)
        if !service_name.match(/sl_|fedora_19/)
          message  = "Locating:\tSyslinux package"
          command  = "cd #{rpm_dir} ; find . -name 'syslinux-[0-9]*' |grep '#{iso_arch}'"
          output   = execute_command(message,command)
          rpm_file = output.chomp
          rpm_file = rpm_file.gsub(/\.\//,"")
          rpm_file = rpm_dir+"/"+rpm_file
          check_dir_exists(pxe_boot_dir)
        else
          rpm_dir  = $work_dir+"/rpm"
          if !File.directory?(rpm_dir)
            check_dir_exists(rpm_dir)
          end
          rpm_url  = "http://"+$local_ubuntu_mirror+"/pub/centos/5/os/i386/CentOS/syslinux-4.02-7.2.el5.i386.rpm"
          rpm_file = rpm_dir+"/syslinux-4.02-7.2.el5.i386.rpm"
          if !File.exist?(rpm_file)
            wget_file(rpm_url,rpm_file)
          end
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
    if service_name.match(/sles/)
      pxe_image_dir=pxe_boot_dir+"/boot"
    else
      pxe_image_dir=pxe_boot_dir+"/images"
    end
    if !File.directory?(pxe_image_dir)
      if service_name.match(/sles/)
        iso_image_dir = $repo_base_dir+"/"+service_name+"/boot"
      else
        iso_image_dir = $repo_base_dir+"/"+service_name+"/images"
      end
      message       = "Copying:\tPXE boot images from "+iso_image_dir+" to "+pxe_image_dir
      command       = "cp -r #{iso_image_dir} #{pxe_boot_dir}"
      output        = execute_command(message,command)
    end
  else
    check_dir_exists(pxe_boot_dir)
    pxe_image_dir = pxe_boot_dir+"/images"
    check_dir_exists(pxe_image_dir)
    pxe_image_dir = pxe_boot_dir+"/images/pxeboot"
    check_dir_exists(pxe_image_dir)
    test_file = pxe_image_dir+"/vmlinuz"
    if service_name.match(/ubuntu/)
      iso_image_dir = $repo_base_dir+"/"+service_name+"/install"
    else
      iso_image_dir = $repo_base_dir+"/"+service_name+"/isolinux"
    end
    if !File.exist?(test_file)
      message = "Copying:\tPXE boot files from "+iso_image_dir+" to "+pxe_image_dir
      command = "cd #{pxe_image_dir} ; cp -r #{iso_image_dir}/* . "
      output  = execute_command(message,command)
    end
  end
  pxe_cfg_dir = $tftp_dir+"/pxelinux.cfg"
  check_dir_exists(pxe_cfg_dir)
  return
end

# Unconfigure PXE boot

def unconfigure_ks_pxe_boot(service_name)
  return
end

# Configure Kickstart server

def configure_ks_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  if service_name.match(/[A-z]/)
    if service_name.downcase.match(/centos/)
      search_string = "CentOS"
    end
    if service_name.downcase.match(/redhat/)
      search_string = "rhel"
    end
    if service_name.downcase.match(/scientific|sl_/)
      search_string = "sl"
    end
    if service_name.downcase.match(/oel/)
      search_string = "OracleLinux"
    end
  else
    search_string = "CentOS|rhel|SL|OracleLinux|Fedora"
  end
  configure_linux_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# Configure local VMware repo

def configure_ks_vmware_repo(service_name,client_arch)
  vmware_dir   = $pkg_base_dir+"/vmware"
  add_apache_alias(vmware_dir)
  repodata_dir = vmware_dir+"/repodata"
  vmware_url   = "http://packages.vmware.com/tools/esx/latest"
  if service_name.match(/centos_5|rhel_5|sl_5|oel_5|fedora_18/)
    vmware_url   = vmware_url+"/rhel5/"+client_arch+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if service_name.match(/centos_6|rhel_6|sl_6|oel_6|rhel_7|fedora_[19,20]/)
    vmware_url   = vmware_url+"/rhel6/"+client_arch+"/"
    repodata_url = vmware_url+"repodata/"
  end
  if $download_mode == 1
    if !File.directory?(vmware_dir)
      check_dir_exists(vmware_dir)
      message = "Fetching:\tVMware RPMs"
      command = "cd #{vmware_dir} ; lftp -e 'mget * ; quit' #{vmware_url}"
      execute_command(message,command)
      check_dir_exists(repodata_dir)
      message = "Fetching:\tVMware RPM repodata"
      command = "cd #{repodata_dir} ; lftp -e 'mget * ; quit' #{repodata_url}"
      execute_command(message,command)
    end
  end
  return
end

# Configure local Puppet repo

def configure_ks_puppet_repo(service_name,iso_arch)
  puppet_rpm_list = {}
  puppet_base_dir = $pkg_base_dir+"/puppet"
  puppet_rpm_list["products"]     = []
  puppet_rpm_list["dependencies"] = []
  puppet_rpm_list["products"].push("facter")
  puppet_rpm_list["products"].push("hiera")
  puppet_rpm_list["products"].push("puppet")
  puppet_rpm_list["dependencies"].push("ruby-augeas")
  puppet_rpm_list["dependencies"].push("ruby-json")
  puppet_rpm_list["dependencies"].push("ruby-shadow")
  puppet_rpm_list["dependencies"].push("ruby-rgen")
  puppet_rpm_list["dependencies"].push("libselinux-ruby")
  check_zfs_fs_exists(puppet_base_dir)
  add_apache_alias(puppet_base_dir)
  rpm_list   = populate_puppet_rpm_list(service_name,iso_arch)
  if !File.directory?(puppet_base_dir)
    check_dir_exists(puppet_base_dir)
  end
  release    = service_name.split(/_/)[1]
  [ "products", "dependency" ].each do |remote_dir|
    puppet_rpm_list[remote_dir].each do |pkg_name|
      if pkg_name.match(/libselinux-ruby/)
        remote_url = $puppet_rpm_base_url+"/el/"+release+"/"+remote_dir+"/"+iso_arch+"/"
      else
        remote_url = $centos_rpm_base_url+"/"+release+"/os/"+iso_arch+"/Packages/"
      end
      rpm_urls = Nokogiri::HTML.parse(remote_url).css('td a')
      pkg_file = rpm_urls.grep(/^#{pkg_name}-[0-9]/)[-1]
      if pkg_file.to_s.match(/href/)
        pkg_file   = URI.parse(pkg_file).to_s
        pkg_url    = puppet_rpm_url+pkg_file
        local_file = puppet_local_dir+"/"+pkg_file
        if !File.exist?(local_file) or File.size(local_file) == 0
          if $verbose_mode == 1
            puts "Fetching "+pkg_url+" to "+local_file
          end
          agent = Mechanize.new
          agent.redirect_ok = true
          agent.pluggable_parser.default = Mechanize::Download
          agent.get(pkg_url).save(local_file)
        end
      end
    end
  end
  return
end

# Configue Linux server

def configure_linux_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  iso_list = []
  check_zfs_fs_exists($client_base_dir)
  check_dhcpd_config(publisher_host)
  if iso_file.match(/[A-z]/)
    if File.exist?(iso_file)
      if !iso_file.match(/CentOS|rhel|Fedora|SL|OracleLinux|ubuntu/)
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
      (linux_distro,iso_version,iso_arch) = get_linux_version_info(iso_file_name)
      iso_version  = iso_version.gsub(/\./,"_")
      service_name = linux_distro+"_"+iso_version+"_"+iso_arch
      repo_version_dir  = $repo_base_dir+"/"+service_name
      if !iso_file_name.match(/DVD2\.iso|2of2\.iso/)
        add_apache_alias(service_name)
        configure_ks_repo(iso_file_name,repo_version_dir)
        configure_ks_pxe_boot(service_name,iso_arch)
        if service_name.match(/centos|fedora|rhel|sl_|oel/)
          configure_ks_vmware_repo(service_name,iso_arch)
        end
        if !service_name.match(/ubuntu|sles/)
          configure_ks_puppet_repo(service_name,iso_arch)
        end
      else
        mount_iso(iso_file)
        copy_iso(iso_file,repo_version_dir)
        umount_iso()
      end
    end
  else
    if service_name.match(/[A-z]/)
      if !client_arch.match(/[A-z]/)
        iso_info    = service_name.split(/_/)
        client_arch = iso_info[-1]
      end
      add_apache_alias(service_name)
      configure_ks_pxe_boot(service_name,client_arch)
      if service_name.match(/centos|fedora|rhel|sl_|oel/)
        configure_ks_vmware_repo(service_name,client_arch)
      end
      if !service_name.match(/ubuntu|sles/)
        configure_ks_puppet_repo(service_name,client_arch)
      end
    else
      puts "Warning:\tISO file and/or Service name not found"
      exit
    end
  end
  return
end

# List kickstart services

def list_ks_services()
  puts
  puts "Kickstart services:"
  puts
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/centos|fedora|rhel|sl_|oel/)
      puts service_name
    end
  end
  puts
  return
end
