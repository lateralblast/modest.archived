#!/usr/bin/env ruby

# Delecte a service
# This will also delete all the clients under it

def delete_ai_service(service_name)
  service_base_name=get_service_base_name(service_name)
  smf_service_name="svc:/application/pkg/server:"+service_base_name
  smf_service_test=%x[svcs -a |grep '#{smf_service_name}']
  if smf_service_test.match(/pkg/)
    disable_smf_service(smf_service_name)
    message="Removing:\tSMF service "+service_base_name
    command="svccfg -s pkg/server delete "+service_base_name
    output=execute_command(message,command)
  end
  if !service_name.match(/i386|sparc/)
    ["i386","sparc"].each do |sys_arch|
      service_test=%x[installadm list |grep #{service_name} |grep #{sys_arch}]
      if service_test.match(/[A-z|0-9]/)

        message="Deleting:\tService "+service_name+"_"+sys_arch+" and all clients under it"
        command="installadm delete-service "+service_name+"_"+sys_arch+" -r -y"
        output=execute_command(message,command)
      end
    end
  else
    service_test=%x[installadm list |grep #{service_name}]
   if service_test.match(/[A-z|0-9]/)
      message="Deleting:\tService "+service_name+" and all clients under it"
      command="installadm delete-service "+service_name+" -r -y"
      output=execute_command(message,command)
    end
  end
  file="/etc/inet/dhcpd4.conf"
  if File.exists?(file)
    backup_file=file+".preai"
    message="Restoring:\tFile "+backup_file+" to "+file
    command="cp #{backup_file} #{file}"
    output=execute_command(message,command)
    mf_service_name="svc:/network/dhcp/server:ipv4"
    refresh_smf_service(smf_service_name)
  end
  remove_apache_proxy(service_name)
  return
end

# Check we've got a default route
# This is required for DHCPd to start

def check_default_route()
  message="Getting:\tdefault route"
  command="netstat -rn |grep default |awk '{print $2}'"
  output=execute_command(message,command)
  if !output.match(/[0-9]/)
    puts "Warning:\tNo default route exists"
    if $test_mode != 1
      exit
    end
  end
  return
end

# Touch /etc/inet/dhcpd4.conf if it doesn't exist
# If you don't do this it won't actually write to the file

def check_dhcpd4_conf()
  file="/etc/inet/dhcpd4.conf"
  puts "Checking:\t"+file+" exists"
  if !File.exists?(file)
    message="Creating:\t"+file
    command="touch #{file}"
    output=execute_command(message,command)
  else
    backup_file=file+".preai"
    message="Archiving:\tFile "+file+" to "+backup_file
    command="cp #{file} #{backup_file}"
    output=execute_command(message,command)
  end
  return
end

# Create a ZFS file system for base directory if it doesn't exist
# Eg /export/auto_install

def check_ai_base_dir()
  puts "Checking:\t"+$ai_base_dir
  output=check_zfs_fs_exists($ai_base_dir)
  return output
end

# Create a ZFS file system for repo directory if it doesn't exist
# Eg /export/repo/11_1 or /export/auto_install/11_1

def check_version_dir(dir_name,repo_version)
  full_version_dir=dir_name+repo_version
  puts "Checking:\t"+full_version_dir
  output=check_zfs_fs_exists(full_version_dir)
  return full_version_dir
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_full_repo_iso(iso_file)
  puts "Processing:\t"+iso_file
  output=check_dir_exists($iso_mount_dir)
  message="Checking:\tExisting mounts"
  command="df |awk '{print $1}' |grep '^#{$iso_mount_dir}$'"
  output=execute_command(message,command)
  if output.match(/[A-z]/)
    message="Unmounting:\t"+$iso_mount_dir
    command="umount "+$iso_mount_dir
    output=execute_command(message,command)
  end
  message="Mounting:\tISO "+iso_file+" on "+$iso_mount_dir
  command="mount -F hsfs "+iso_file+" "+$iso_mount_dir
  output=execute_command(message,command)
  iso_repo_dir=$iso_mount_dir+"/repo"
  if !File.directory?(iso_repo_dir)
    puts "Warning:\tISO did not mount, or this is not a repository ISO"
    puts "Warning:\t"+iso_repo_dir+" does not exit"
    if $test_mode != 1
      exit
    end
  end
  return
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def check_iso_base_dir()
  iso_list=[]
  puts "Checking:\t"+$iso_base_dir
  output=check_zfs_fs_exists($iso_base_dir)
  message="Getting:\t"+$iso_base_dir+" contents"
  command="ls #{$iso_base_dir}/*repo-full*.iso"
  iso_list=execute_command(message,command)
  if !iso_list.grep(/full/)
    puts "Warning:\tNo full repository ISO images exist in "+$iso_base_dir
    if $test_mode != 1
      exit
    end
  end
  return iso_list
end

# Copy repository from ISO to local filesystem

def copy_repo_iso(repo_version_dir)
  puts "Checking:\tIf we can copy data from full repo ISO"
  iso_repo_dir=$iso_mount_dir+"/repo"
  if !File.directory?(repo_version_dir)
    puts "Warning:\tRepository directory "+repo_version_dir+" does not exist"
    if $test_mode != 1
      exit
    end
  end
  test_dir=repo_version_dir+"/publisher"
  if !File.directory?(test_dir)
    message="Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
    command="rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
    output=execute_command(message,command)
    message="Rebuilding:\tRepository in "+repo_version_dir
    command="pkgrepo -s #{repo_version_dir} rebuild"
    output=execute_command(message,command)
  end
  return
end

# Routine to create AI service

def create_ai_services(iso_repo_version,publisher_url,client_arch)
  puts "Creating:\tAI services"
  client_arch_list=[]
  if !client_arch.downcase.match(/i386|sparc/)
    client_arch_list=["i386","SPARC"]
  else
    client_arch_list=["#{client_arch}"]
  end
  client_arch_list.each do |sys_arch|
    lc_sys_arch=sys_arch.downcase
    auto_install_dir=$ai_base_dir+"/"+iso_repo_version+"_"+lc_sys_arch
    service_name=iso_repo_version+"_"+lc_sys_arch
    #check_zfs_fs_exists(auto_install_dir)
    message="Creating:\tAI service for #{lc_sys_arch}"
    command="installadm create-service -a #{lc_sys_arch} -n #{service_name} -p solaris=#{publisher_url} -d #{auto_install_dir}"
    execute_command(message,command)
  end
  return
end

# Get repo version directory
# Determine the directory for the repo
# Eg /export/repo/solaris/11/X.X.X

def get_repo_version_dir(iso_repo_version)
  repo_version_dir=$repo_base_dir+"/"+iso_repo_version
  return repo_version_dir
end

# Check ZFS filesystem or mount point exists for repo version directory

def check_repo_version_dir(repo_version_dir)
  dir_list=repo_version_dir.split(/\//)
  check_dir=""
  dir_list.each do |dir_name|
    check_dir=check_dir+"/"+dir_name
    check_dir=check_dir.gsub(/\/\//,"/")
    if dir_name.match(/[A-z|0-9]/)
      check_zfs_fs_exists(check_dir)
    end
  end
  return
end

# Get a list of the installed AI services

def get_install_services()
  message="Getting:\tList of AI services"
  command="installadm list"
  output=execute_command(message,command)
  return output
end

# Add apache proxy

def add_apache_proxy(publisher_host,publisher_port,service_base_name)
  apache_config_file="/etc/apache2/2.2/httpd.conf"
  apache_check=%x[cat #{apache_config_file} |grep #{service_base_name}]
  if !apache_check.match(/#{service_base_name}/)
    message="Archiving:\t"+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command="cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(message,command)
    message="Adding:\t\tProxy entry to "+apache_config_file
    command="echo 'ProxyPass /"+service_base_name+" http://"+publisher_host+":"+publisher_port+" nocanon max=200' >>"+apache_config_file
    execute_command(message,command)
    smf_service_name="apache22"
    enable_smf_service(smf_service_name)
    refresh_smf_service(smf_service_name)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  apache_config_file="/etc/apache2/2.2/httpd.conf"
  apache_check=%x[cat #{apache_config_file} |grep #{service_base_name}]
  if apache_check.match(/#{service_base_name}/)
    message="Restoring:\t"+apache_config_file+".no_"+service_base_name+" to "+apache_config_file
    command="cp #{apache_config_file}.no_#{service_base_name} #{apache_config_file}"
    execute_command(message,command)
    smf_service_name="apache22"
    refresh_smf_service(smf_service_name)
  end
end

# Create server manifest for AI service

def create_ai_server_manifest(publisher_host,publisher_port,service_name,repo_version_dir)
  message=""
  commands=[]
  commands.push("svccfg -s pkg/server add #{service_name}")
  commands.push("svccfg -s pkg/server:#{service_name} addpg pkg application")
  commands.push("svccfg -s pkg/server:#{service_name} setprop pkg/port=#{publisher_port}")
  commands.push("svccfg -s pkg/server:#{service_name} setprop pkg/inst_root=#{repo_version_dir}")
  commands.push("svccfg -s pkg/server:#{service_name} addpg general framework")
  commands.push("svccfg -s pkg/server:#{service_name} addpropvalue general/complete astring: #{service_name}")
  commands.push("svccfg -s pkg/server:#{service_name} addpropvalue general/enabled boolean: true")
  commands.push("svccfg -s pkg/server:#{service_name} setprop pkg/readonly=true")
  commands.push("svccfg -s pkg/server:#{service_name} setprop pkg/proxy_base = astring: http://#{publisher_host}/#{service_name}")
  commands.each do |command|
    execute_command(message,command)
  end
  return
end

# Code to get Solaris relase from file system under repository

def get_ai_solaris_release(repo_version_dir)
  iso_repo_version=""
  manifest_dir=repo_version_dir+"/publisher/solaris/pkg/release%2Fname"
  if File.directory?(manifest_dir)
    message="Locating:\tRelease file"
    command="cat #{manifest_dir}/* |grep 'release' |grep '^file' |head -1 |awk '{print $2}'"
    output=execute_command(message,command)
    release_file=output.chomp
    release_dir=release_file[0..1]
    release_file=repo_version_dir+"publisher/solaris/file/"+release_dir+"/"+release_file
    if File.exists?(release_file)
      message="Getting\tRelease information"
      command="gzcat #{release_file} |head -1 |awk '{print $3}'"
      output=execute_command(message,command)
      iso_repo_version=output.chomp.gsub(/\./,"_")
    else
      puts "Warning:\tCould not find "+release_file
      puts "Warning:\tCould not verify solaris release from repository"
      puts "Seeting:\tSolaris release to 11"
      iso_repo_version="11"
    end
  end
  iso_repo_version="sol_"+iso_repo_version
  return iso_repo_version
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def fix_server_dhcpd_range(publisher_host)
  copy=[]
  file="/etc/inet/dhcpd4.conf"
  date_string=get_date_string()
  dhcpd_range=publisher_host.split(/\./)[0..2]
  dhcpd_range=dhcpd_range.join(".")
  backup_file=$work_dir+"/dhcpd4.conf."+date_string
  message="Archiving:\tFile "+file+" to "+backup_file
  command="cp #{file} #{backup_file}"
  output=execute_command(message,command)
  text=File.read(file)
  text.each do |line|
    if line.match(/range #{dhcpd_range}/) and !line.match(/^#/)
      line="#"+line
      copy.push(line)
    else
      copy.push(line)
    end
  end
  File.open(file,"w") {|file| file.puts copy}
  return
end


# Main server routine called from modest main code

def configure_ai_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  iso_list=[]
  # Check we have a default route (required for DHCPd to start)
  check_default_route()
  # Check that we have a DHCPd config file to write to
  check_dhcpd4_conf()
  # Check that we have a local repoistory
  publisher_url=get_publisher_url(publisher_host,publisher_port)
  # Get a list of installed services
  services_list=get_install_services()
  # If we don't have a local repository start setting one up
  if publisher_url.match(/oracle/) or services_list.grep(/No services configured/)
    # Check if we have a file based repository we can use
    message="Checking:\tIf file based repository exists"
    command="pkg publisher |grep online |grep file |awk '{print $5}'"
    output=execute_command(message,command)
    file_repo_url=output.chomp
    if file_repo_url.match(/file/)
      (repo_type,repo_version_dir)=file_repo_url.split(/:\/\//)
      iso_repo_version=get_ai_solaris_release(repo_version_dir)
      if !service_name.match(/[A-z|0-9]/)
        service_base_name=iso_repo_version
      else
        service_base_name=get_service_base_name(service_name)
      end
      ai_version_dir=check_ai_base_dir()
      create_ai_server_manifest(publisher_host,publisher_port,service_base_name,repo_version_dir)
      add_apache_proxy(publisher_host,publisher_port,service_base_name)
      create_ai_services(iso_repo_version,publisher_url,client_arch)
    else
      # Check we have ISO to get repository data from
      if !iso_file.match(/[A-z|0-9]/)
        if File.exists?(iso_file)
          iso_list[0]=iso_file
        else
          iso_list=check_iso_base_dir()
        end
      else
        iso_list=check_iso_base_dir()
      end
      # If we do have ISO use them to set up repositories
      if iso_list.grep(/full/)
        # If we have a repo ISO process it
        iso_list.each do |iso_file|
          iso_file=iso_file.chomp
          mount_full_repo_iso(iso_file)
          # Get repo version from file name
          # Eg sol-11_1-repo-full.iso
          # Would be 11_1
          # And sol-11_1_13_6_0-incr-repo.iso
          # would be 11_1_13_6_0
          iso_repo_version=File.basename(iso_file,".iso")
          iso_repo_version=iso_repo_version.split(/-/)[1]
          iso_repo_version="sol_"+iso_repo_version
          if !service_name.match(/[A-z|0-9]/)
            service_base_name=iso_repo_version
          else
            service_base_name=get_service_base_name(service_name)
          end
          repo_version_dir=get_repo_version_dir(iso_repo_version)
          if !iso_repo_version.match(/11/)
            iso_repo_version=get_ai_solaris_release(repo_version_dir)
          end
          check_repo_version_dir(repo_version_dir)
          copy_repo_iso(repo_version_dir)
          ai_version_dir=check_ai_base_dir()
          #repo_version=get_repo_version()
          create_ai_server_manifest(publisher_host,publisher_port,service_base_name,repo_version_dir)
          add_apache_proxy(publisher_host,publisher_port,service_base_name)
          create_ai_services(iso_repo_version,publisher_url,client_arch)
        end
      end
    end
    fix_server_dhcpd_range(publisher_host)
  end
  return
end
