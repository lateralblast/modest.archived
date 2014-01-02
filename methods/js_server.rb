
# Jupstart server code

# Configure NFS services

def configure_js_nfs_services(repo_version_dir)
  exports_file+"/etc/dfs/dfstab"
  message="Checking:\tNFS exports file "+exports_file+" for "+repo_version_dir
  command="cat #{exports_file} | grep #{repo_version_dir}"
  output=execute_command(message,command)
  if !output.match(/#{repo_version_dir}/)
    backup_file=exports_file+".prejs"
    message="Archiving:\tNFS exports file "+exports
    command="cp #{exports_file} #{backup_file}"
    output=execute_command(message,command)
    message="Adding:\tNFS export "+repo_version_dir+" to "+exports_file
    command"echo 'share -F nfs -o ro,anon=0 #{repo_version_dir}' >> #{exports_file}"
  end
  return
end

# Configure tftpboot services

def configure_js_tftp_services()
  pkg_name="system/boot/network"
  message="Checking:\tBoot server package is installed"
  command="pkginfo #{pkg_name} |grep Name |awk '{print $2}'"
  output=execute_command(message,command)
  if !output.match(/#{pkg_name}/)
    message="Installing:\tBoot server package"
    command="pkg install #{pkg_name}"
    output=execute_command(message,command)
  end
  tftp_dir="/tftpboot"
  netboot_dir="/etc/netboot"
  if !File.symlink?(tftp_dir)
    message="Symlinking:\tDirectory "+tftp_dir+" to "+netboot_dir
    command="ln -s #{tftp_dir} #{netboot_dir}"
    output=execute_command(message,command)
  end
  smf_service_name="svc:/network/tftp/udp6:default"
  message="Checking:\tTFTP service is installed"
  command="svcs -a |grep '#{smf_service_name}'"
  output=execute_command(message,command)
  if !output.match(/#{smf_service_name}/)
    meesage="Creating:\tTFTP service information"
    command="echo 'tftp  dgram  udp6  wait  root  /usr/sbin/in.tftpd  in.tftpd -s /tftpboot' >> /tmp/tftp"
    output=execute_command(message,command)
    message="Creating:\tTFTP service manifest"
    command="inetconv -i /tmp/tftp"
    output=execute_command(message,command)
  end
  enable_smf_service(smf_service_name)
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
    boot_file=repo_version_dir+"/Solaris_"+os_version+"/Boot/platform/"+boot_arch+"/inetboot"
    tftp_file=tftp_dir+"/"+boot_arch+".inetboot.sol_"+os_version+"_"+os_update
    if !File.exists?(boot_file)
      message="Copying:\tBoot image "+boot_file+" to "+tftp_file
      command="cp #{boot_file} #{tftp_file}"
      output=execute_command(message,command)
    end
  end
  return
end

# Configure Jumpstart repo

def configure_js_repo(iso_file,repo_version_dir,os_version)
  check_zfs_fs_exists(repo_version_dir)
  check_dir=$repo_version_dir+"/boot"
  if $verbose_mode == 1
    puts "Checking:\tDirectory "+check_dir+" exits"
  end
  if !File.directory?(check_dir)
    mount_iso(iso_file)
    check_dir=$iso_mount_dir+"/boot"
    if $verbose_mode == 1
      puts "Checking:\tDirectory "+check_dir+" exits"
    end
    if File.directory?(check_dir)
      iso_update=get_js_iso_update($iso_mount_dir)
      if iso_update != os_update
        puts "Warning:\tISO update version does not ISO name"
        return
      end
      message="Copying:\tISO file "+iso_file+" contents to "+repo_version_dir
      command="cd /cdrom/Solaris_#{os_version}/Tools ; ./setup_install_server #{repo_version_dir}"
      output=execute_command(message,command)
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
  file_name="rm_install_client"
  file=repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  backup_file=rm_script+".modest"
  if !File.exists?(backup_file)
    message="Archiving:\tRemove install script "+rm_script+" to "+backup_file
    command="cp #{rm_script} #{backup_file}"
    output=execute_command(message,command)
    text=File.read(file)
    text.each do |line|
      if line.match(/ANS/) and line.match(/sed/) and !line.match(/\{/)
        line=line.gsub(/#/,' #')
      end
      if line.match(/nslookup/) and !line.match(/sed/)
        line="ANS=`nslookup ${K} | /bin/sed '/^;;/d' 2>&1`"
      end
      copy.push(line)
    end
    File.open(file,"w") {|file| file.puts copy}
  end
  return
end

# List Jumpstart services

def list_js_services()
  puts "Jumpstart services:"
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
  file_name="check"
  file=repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  backup_file=rm_script+".modest"
  if !File.exists?(backup_file)
    message="Archiving:\tCheck script "+rm_script+" to "+backup_file
    command="cp #{rm_script} #{backup_file}"
    output=execute_command(message,command)
    text=File.read(file)
    copy=text
    copy[0]="#!/usr/has/bin/sh\n"
    File.open(file,"w") {|file| file.puts copy}
  end
  return
end

# Configure jumpstart server

def configure_js_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  iso_list=[]
  search_string="-ga-"
  if iso_file.match(/[A-z]/)
    if File.exists?(iso_file)
      iso_list[0]=iso_file
    else
      puts "Warning:\tISO file "+is_file+" does not exist"
    end
  else
    iso_list=check_iso_base_dir(search_string)
  end
  iso_list.each do |iso_file|
    iso_file=iso_file.chomp
    iso_info=File.basename(iso_file)
    iso_info=iso_info.split(/-/)
    os_version=iso_info[1]
    os_update=iso_info[2]
    os_arch=iso_info[3]
    if !solaris_arch.match(/sparc/)
      solaris_arch="i386"
    end
    release_dir="sol_"+os_version+"_"+os_update+"_"+os_arch
    repo_version_dir=$repo_base_dir+"/"+release_dir
    add_apache_alias(release_dir)
    configure_js_repo(iso_file,repo_version_dir,os_version)
    configure_js_tftp_services()
    if os_arch.match(/sparc/)
      copy_js_sparc_boot_images(repo_version_dir,os_version,os_update)
    end
    fix_js_rm_client(repo_version_dir,os_version)
    fix_js_check(repo_version_dir,os_version)
  end
  return
end
