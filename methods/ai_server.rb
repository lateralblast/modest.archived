
# AI server code

# List available ISOs

def list_ai_isos()
  search_string = "repo-full"
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file|
    iso_file    = iso_file.chomp
    iso_info    = File.basename(iso_file)
    iso_info    = iso_info.split(/-/)
    if iso_file.match(/beta/)
      iso_version = iso_info[1]+"_beta"
    else
      iso_version = iso_info[1]
    end
    puts "ISO file:\t"+iso_file
    puts "Distribution:\tSolaris"
    puts "Version:\t"+iso_version.gsub(/_/,".")
    puts "Architecture:\tSPARC and i386"
    service_name     = "sol_"+iso_version
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      puts "Service Name:\t"+service_name+" (exists)"
    else
      puts "Service Name:\t"+service_name
    end
  end
  return
end

# Delecte a service
# This will also delete all the clients under it

def unconfigure_ai_server(service_name)
  if $os_name.match(/SunOS/)
    service_base_name = get_service_base_name(service_name)
    smf_service_name  = "svc:/application/pkg/server:"+service_base_name
    smf_service_test  = %x[svcs -a |grep '#{smf_service_name}']
    if smf_service_test.match(/pkg/)
      unconfigure_ai_pkg_repo(smf_service_name)
    end
    if !service_name.match(/i386|sparc/)
      ["i386","sparc"].each do |sys_arch|
        service_test=%x[installadm list |grep #{service_name} |grep #{sys_arch}]
        if service_test.match(/[A-z|0-9]/)
          message = "Deleting:\tService "+service_name+"_"+sys_arch+" and all clients under it"
          command = "installadm delete-service "+service_name+"_"+sys_arch+" -r -y"
          execute_command(message,command)
        end
      end
    else
      service_test=%x[installadm list |grep #{service_name}]
      if service_test.match(/[A-z|0-9]/)
        message = "Deleting:\tService "+service_name+" and all clients under it"
        command = "installadm delete-service "+service_name+" -r -y"
        execute_command(message,command)
      end
    end
    file="/etc/inet/dhcpd4.conf"
    if File.exist?(file)
      backup_file     = file+".preai"
      message         = "Restoring:\tFile "+backup_file+" to "+file
      command         = "cp #{backup_file} #{file}"
      execute_command(message,command)
      smf_service_name = "svc:/network/dhcp/server:ipv4"
      refresh_smf_service(smf_service_name)
    end
    remove_apache_proxy(service_name)
    repo_version_dir = $repo_base_dir+"/"+service_base_name
    test_dir = repo_version_dir+"/publisher"
    if File.directory?(test_dir)
      destroy_zfs_fs(repo_version_dir)
    end
  else
    remove_apache_proxy(service_name)
  end
  return
end

# Check we've got a default route
# This is required for DHCPd to start

def check_default_route()
  message = "Getting:\tdefault route"
  command = "netstat -rn |grep default |awk '{print $2}'"
  output  = execute_command(message,command)
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
  if $os_name.match(/SunOS/)
    file="/etc/inet/dhcpd4.conf"
    if $verbose_mode == 1
      puts "Checking:\t"+file+" exists"
    end
    if !File.exist?(file)
      message = "Creating:\t"+file
      command = "touch #{file}"
      output  = execute_command(message,command)
    else
      backup_file = file+".preai"
      message     = "Archiving:\tFile "+file+" to "+backup_file
      command     = "cp #{file} #{backup_file}"
      output      = execute_command(message,command)
    end
  end
  return
end

# Create a ZFS file system for base directory if it doesn't exist
# Eg /export/auto_install

def check_ai_base_dir()
  if $verbose_mode == 1
    puts "Checking:\t"+$ai_base_dir
  end
  output = check_zfs_fs_exists($ai_base_dir)
  return output
end

# Create a ZFS file system for repo directory if it doesn't exist
# Eg /export/repo/11_1 or /export/auto_install/11_1

def check_version_dir(dir_name,repo_version)
  full_version_dir=dir_name+repo_version
  puts "Checking:\t"+full_version_dir
  check_zfs_fs_exists(full_version_dir)
  return full_version_dir
end

# Check AI service is running

def check_ai_service(service_name)
  message = "Checking:\tAI service "+service_name
  if $os_name.match(/SunOS/)
    if service_name.match(/alt/)
      command = "installadm list |grep '#{service_name}'"
    else
      command = "installadm list |grep '#{service_name}' |grep -v alt"
    end
  else
    command = "ls #{$repo_base_dir} |grep '#{service_name}'"
  end
  output  = execute_command(message,command)
  return output
end

# Routine to create AI service

def configure_ai_services(iso_repo_version,publisher_url,client_arch)
  puts "Creating:\tAI services"
  client_arch_list = []
  if !client_arch.downcase.match(/i386|sparc/)
    client_arch_list = ["i386","SPARC"]
  else
    client_arch_list = ["#{client_arch}"]
  end
  client_arch_list.each do |sys_arch|
    lc_arch = sys_arch.downcase
    ai_dir  = $ai_base_dir+"/"+iso_repo_version+"_"+lc_arch
    service_name = iso_repo_version+"_"+lc_arch
    if $os_name.match(/SunOS/)
      service_check = check_ai_service(service_name)
      if !service_check.match(/#{service_name}/)
        message = "Creating:\tAI service for #{lc_arch}"
        command = "installadm create-service -a #{lc_arch} -n #{service_name} -p solaris=#{publisher_url} -d #{ai_dir}"
        execute_command(message,command)
      end
    else
      service_info = service_name.split(/_/)
      client_ver   = service_info[1]
      client_rel   = service_info[2]
      ai_iso_file  = "sol-"+client_ver+"_"+client_rel+"-ai-"+lc_arch+".iso"
      ai_iso_file  = $iso_base_dir+"/"+ai_iso_file
      if !File.exist?(ai_iso_file)
        puts "Warning:\tAI ISO file "+ai_iso_file+" not found for architecture "+lc_arch
      else
        if $os_name.match(/Darwin/)
          tftp_version_dir = $tftp_dir+"/"+service_name
          output = check_osx_iso_mount(tftp_version_dir,ai_iso_file)
          if output.match(/Resource busy/)
            puts "Warning:\t ISO already mounted"
            exit
          end
        end
      end
    end
  end
  return
end

# Get repo version directory
# Determine the directory for the repo
# Eg /export/repo/solaris/11/X.X.X

def get_repo_version_dir(iso_repo_version)
  repo_version_dir = $repo_base_dir+"/"+iso_repo_version
  return repo_version_dir
end

# Check ZFS filesystem or mount point exists for repo version directory

def check_repo_version_dir(repo_version_dir)
  dir_list=repo_version_dir.split(/\//)
  check_dir=""
  dir_list.each do |dir_name|
    check_dir = check_dir+"/"+dir_name
    check_dir = check_dir.gsub(/\/\//,"/")
    if dir_name.match(/[A-z|0-9]/)
      check_zfs_fs_exists(check_dir)
    end
  end
  return
end

# Get a list of the installed AI services

def get_ai_install_services()
  message = "Getting:\tList of AI services"
  if $os_name.match(/SunOS/)
    command = "installadm list |grep '^sol_11' |awk '{print $1}'"
  else
    command = "ls #{$repo_base_dir} |grep 'sol_11'"
  end
  output = execute_command(message,command)
  return output
end

# Code to get Solaris relase from file system under repository

def get_ai_solaris_release(repo_version_dir)
  iso_repo_version = ""
  manifest_dir     = repo_version_dir+"/publisher/solaris/pkg/release%2Fname"
  if File.directory?(manifest_dir)
    message      = "Locating:\tRelease file"
    command      = "cat #{manifest_dir}/* |grep 'release' |grep '^file' |head -1 |awk '{print $2}'"
    output       = execute_command(message,command)
    release_file = output.chomp
    release_dir  = release_file[0..1]
    release_file = repo_version_dir+"publisher/solaris/file/"+release_dir+"/"+release_file
    if File.exist?(release_file)
      message          = "Getting\tRelease information"
      command          = "gzcat #{release_file} |head -1 |awk '{print $3}'"
      output           = execute_command(message,command)
      iso_repo_version = output.chomp.gsub(/\./,"_")
    else
      puts "Warning:\tCould not find "+release_file
      puts "Warning:\tCould not verify solaris release from repository"
      puts "Setting:\tSolaris release to 11"
      iso_repo_version="11"
    end
  end
  iso_repo_version="sol_"+iso_repo_version
  return iso_repo_version
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def fix_server_dhcpd_range(publisher_host)
  copy        = []
  dhcp_file  = "/etc/inet/dhcpd4.conf"
  dhcpd_range = publisher_host.split(/\./)[0..2]
  dhcpd_range = dhcpd_range.join(".")
  backup_file(dhcp_file)
  text        = File.read(dhcp_file)
  text.each do |line|
    if line.match(/range #{dhcpd_range}/) and !line.match(/^#/)
      line = "#"+line
      copy.push(line)
    else
      copy.push(line)
    end
  end
  File.open(dhcp_file,"w") {|file| file.puts copy}
  return
end

# Main server routine called from modest main code

def configure_ai_server(client_arch,publisher_host,publisher_port,service_name,file_name)
  # Enable default package service
  clear_service("svc:/system/install/server:default")
  enable_service("svc:/system/install/server:default")
  iso_list = []
  # Check we have a default route (required for DHCPd to start)
  check_default_route()
  # Check that we have a DHCPd config file to write to
  check_dhcpd4_conf()
  check_dhcpd_config(publisher_host)
  # Get a list of installed services
  services_list = get_ai_install_services()
  # If given a service name check the service doesn't already exist
  if service_name.match(/[A-z]/)
    if services_list.match(/#{service_name}/)
      puts "Warning:\tService "+service_name+" already exists"
      exit
    end
  end
  # Check we have ISO to get repository data from
  if !file_name.match(/[A-z|0-9]/)
    if service_name.match(/[A-z]/)
      search_string = service_name.gsub(/i386|sparc/,"")
      search_string = search_string.gsub(/sol_/,"sol-")
      search_string = search_string.gsub(/_beta/,"-beta")
      search_string = search_string+"-repo-full"
    else
      search_string = "repo-full"
    end
    iso_list = check_iso_base_dir(search_string)
  else
    iso_list[0] = file_name
  end
  if !iso_list[0]
    puts "Warning:\tNo suitable ISOs found"
    exit
  end
  iso_list.each do |iso_file|
    if File.exist?(iso_file)
      if !iso_file.match(/repo-full/)
        puts "Warning:\tISO "+iso_file+" does not appear to be a valid Solaris distribution"
        exit
      end
    else
      puts "Warning:\tISO "+iso_file+" does not exist"
      exit
    end
    iso_repo_version = File.basename(iso_file,".iso")
    iso_repo_version = iso_repo_version.split(/-/)[1]
    if iso_file.match(/beta/)
      iso_repo_version = "sol_"+iso_repo_version+"_beta"
    else
      iso_repo_version = "sol_"+iso_repo_version
    end
    if !service_name.match(/[A-z|0-9]/)
      service_base_name = iso_repo_version
    else
      service_base_name = get_service_base_name(service_name)
    end
    repo_version_dir = get_repo_version_dir(iso_repo_version)
    if !iso_repo_version.match(/11/)
      iso_repo_version = get_ai_solaris_release(repo_version_dir)
    end
    test_dir = repo_version_dir+"/publisher"
    if !File.directory?(test_dir)
      check_repo_version_dir(repo_version_dir)
      copy_iso(iso_file,repo_version_dir)
    end
    check_ai_base_dir()
    read_only = "true"
    publisher_port = check_publisher_port(publisher_port)
    configure_ai_pkg_repo(publisher_host,publisher_port,service_base_name,repo_version_dir,read_only)
    if $use_alt_repo == 1
      alt_service_name=check_alt_service_name(service_name)
      configure_ai_alt_pkg_repo(publisher_host,publisher_port,alt_service_name)
    end
    publisher_url = get_ai_publisher_url(publisher_host,publisher_port)
    configure_ai_services(iso_repo_version,publisher_url,client_arch)
    configure_ai_client_services(client_arch,publisher_host,publisher_port,service_name)
  end
  fix_server_dhcpd_range(publisher_host)
end

# List AI services

def list_ai_services()
  message = "Listing:\nAvoilable AI services"
  command = "installadm list |grep 'auto_install' |grep -v default |awk '{print $1}'"
  output  = execute_command(message,command)
  puts "Available AI services:"
  puts
  puts output
  return
end
