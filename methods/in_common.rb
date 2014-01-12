
# Code common to all services

# Add hosts entry

def add_hosts_entry(client_name,client_ip)
  hosts_file="/etc/hosts"
  message = "Checking:\tHosts file for "+client_name
  command = "cat #{hosts_file} |grep -v '^#' |grep '#{client_name}' |grep '#{client_ip}'"
  output  = execute_command(message,command)
  if !output.match(/#{client_name}/)
    backup_file(hosts_file)
    message = "Adding:\tHost "+client_name+" to "+hosts_file
    command = "echo '#{client_name}\t#{client_ip}' >> #{hosts_file}"
    output  = execute_command(message,command)
  end
  return
end

# Remove hosts entry

def remove_hosts_entry(client_name,client_ip)
  file_name="/etc/hosts"
  message = "Checking:\tHosts file for "+client_name
  command = "cat #{file_name} |grep -v '^#' |grep '#{client_name}' |grep '#{client_ip}'"
  output  = execute_command(message,command)
  copy=[]
  if output.match(/#{client_name}/)
    file_info=IO.readlines(file_name)
    file_info.each do |line|
      if !line.match(/^#{client_ip}/)
        if !line.mtach(/#{client_name}/)
          copy.push(line)
        end
      end
    end
  end
  File.open(file_name,"w") {|file| file.puts copy}
  return
end

# Add host to DHCP config

def add_dhcp_client(client_name,client_mac,client_ip,service_name)
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  if service_name.match(/sol/)
    suffix = ".bios"
  else
    suffix = ".pxelinux"
  end
  tftp_pxe_file = "01"+tftp_pxe_file+suffix
  dhcpd_file = "/etc/inet/dhcpd4.conf"
  message    = "Checking:\fIf DHCPd configuration contains "+client_name
  command    = "cat #{dhcpd_file} | grep '#{client_name}'"
  output     = execute_command(message,command)
  if !output.match(/#{client_name}/)
    backup_file(dhcpd_file)
    file=File.open(dhcpd_file,"a")
    file.write("\n")
    file.write("host #{client_name} {\n")
    file.write("  fixed-address #{client_ip};\n")
    file.write("  hardware ethernet #{client_mac};\n")
    file.write("  filename \"#{tftp_pxe_file}\";\n")
    file.write("}\n")
    file.close
    restart_dhcpd()
  end
  return
end

# Remove host from DHCP config

def remove_dhcp_client(client_name)
  file_name = "/etc/inet/dhcpd4.conf"
  found     = 0
  copy      = []
  file_info = IO.readlines(file_name)
  file_info.each do |line|
    if line.match(/^host #{client_name}/)
      found=1
    end
    if found == 0
      copy.push(line)
    end
    if found == 1 and line.match(/\}/)
      found=0
    end
  end
  File.open(file_name,"w") {|file| file.puts copy}
  return
end

# Backup file

def backup_file(file_name)
  date_string = get_date_string()
  backup_file = File.basename(file_name)+"."+date_string
  backup_file = $backup_dir+backup_file
  message     = "Archiving:\tFile "+file_name+" to "+backup_file
  command     = "cp #{file_name} #{backup_file}"
  execute_command(message,command)
  return
end

# Wget a file

def wget_file(file_url,file_name)
  file_dir = File.dirname(file_name)
  check_dir_exists(file_dir)
  message  = "Fetching:\tURL "+file_url+" to "+file_name
  command  = "wget #{file_url} -O #{file_name}"
  execute_command(message,command)
  return
end
# Find client MAC

def get_client_mac(client_name)
  ethers_file = "/etc/ethers"
  output      = ""
  found       = 0
  if File.exists?(ethers_file)
    message    = "Checking:\tFile "+ethers_file+" for "+client_name+" MAC address"
    command    = "cat #{ethers_file} |grep '#{client_name} '|awk '{print $2}'"
    client_mac = execute_command(message,command)
    client_mac = client_mac.chomp
  end
  if !output.match(/[0-9]/)
    dhcpd_file="/etc/inet/dhcpd4.conf"
    file=IO.readlines(dhcpd_file)
    file.each do |line|
      line=line.chomp
      if line.match(/#{client_name}/)
        found=1
      end
      if found == 1
        if line.match(/ethernet/)
          client_mac=line.split(/ ethernet /)[1]
          client_mac=client_mac.gsub(/\;/,"")
          return client_mac
        end
      end
    end
  end
  return client_mac
end

# Check if a directory exists
# If not create it

def check_dir_exists(dir_name)
  output  = ""
  if !File.directory?(dir_name)
  message = "Creating:\t"+dir_name
  command = "mkdir -p '#{dir_name}'"
  output  = execute_command(message,command)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(dir_name)
  output=""
  if !File.directory?(dir_name)
    message     = "Warning:\t"+dir_name+" does not exist"
    zfs_name    = $default_zpool+dir_name
    command     = "zfs create #{$zfs_name}"
    output      = execute_command(message,command)
    if dir_name.match(/vmware/)
      service_name = File.basename(dir_name)
      mount_dir    = $tftp_dir+"/"+service_name
      message      = "Information:\tVMware repository being mounted under "+mount_dir
      command      = "zfs set mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(message,command)
      message = "Information:\tSymlinking "+mount_dir+" to "+dir_name
      command = "ln -s #{mount_dir} #{dir_name}"
      execute_command(message,command)
    end
  end
  return output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(dir_name)
  output=""
  if $destroy_fs == 1
    if File.directory?(dir_name)
      message = "Warning:\tDestroying "+dir_name
      command = "zfs destroy #{$default_zpool}#{dir_name}"
      output  = execute_command(message,command)
    end
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(message,command)
  output = ""
  if $verbose_mode == 1
    if message.match(/[A-z|0-9]/)
      puts message
    end
    puts "Executing:\t"+command
  end
  if $test_mode == 1
    if !command.match(/create|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage/)
      output = %x[#{command}]
    end
  else
    output = %x[#{command}]
  end
  if $verbose_mode == 1
    if output.length > 1
      if !output.match(/\n/)
        puts "Output:\t\t"+output
      else
        multi_line_output = output.split(/\n/)
        multi_line_output.each do |line|
          puts "Output:\t\t"+line
        end
      end
    end
  end
  return output
end

# Convert current date to a string that can be used in file names

def get_date_string()
  time        = Time.new
  time        = time.to_a
  date        = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/,"_")
  date_string = date_string.gsub(/:/,"_")
  date_string = date_string.gsub(/-/,"_")
  if $verbose_mode == 1
    puts "Information:\tSetting date string to "+date_string
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  possible = [('a'..'z'),('A'..'Z'),(0..9),'.','/'].inject([]) {|s,r| s+Array(r)}
  salt     = Array.new(8){possible[rand(possible.size)]}
  password = password.crypt("$1$#{salt}")
  return password
end

# Handle SMF service

def handle_smf_service(function,smf_service_name)
  uc_function = function.capitalize
  message     = uc_function+":\tService "+smf_service_name
  command     = "svcadm #{function} #{smf_service_name} ; sleep 5"
  output      = execute_command(message,command)
  return output
end

# Restart DHCPd

def restart_dhcpd()
  function         = "refresh"
  smf_service_name = "svc:/network/dhcp/server:ipv4"
  output           = handle_smf_service(function,smf_service_name)
  return output
end

# Disable SMF service

def disable_smf_service(smf_service_name)
  function = "disable"
  output   = handle_smf_service(function,smf_service_name)
  return output
end

# Enable SMF service

def enable_smf_service(smf_service_name)
  function = "enable"
  output   = handle_smf_service(function,smf_service_name)
  return output
end

# Refresh SMF service

def refresh_smf_service(smf_service_name)
  function = "refresh"
  output   = handle_smf_service(function,smf_service_name)
  return output
end

# Check SMF service

def check_smf_service(smf_service_name)
  message = "Checking:\tService "+smf_service_name
  command = "svcs -a |grep '#{smf_service_name}"
  output  = execute_command(message,command)
  return output
end

# Calculate route

def get_ipv4_default_route(client_ip)
  octets             = client_ip.split(/\./)
  octets[3]          = "254"
  ipv4_default_route = octets.join(".")
  return ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def check_iso_base_dir(search_string)
  iso_list = []
  puts "Checking:\t"+$iso_base_dir
  check_zfs_fs_exists($iso_base_dir)
  message  = "Getting:\t"+$iso_base_dir+" contents"
  command  = "ls #{$iso_base_dir}/*.iso |egrep \"#{search_string}\""
  iso_list = execute_command(message,command)
  if !iso_list.grep(/full/)
    puts "Warning:\tNo full repository ISO images exist in "+$iso_base_dir
    if $test_mode != 1
      exit
    end
  end
  return iso_list
end

# Check client architecture

def check_client_arch(client_arch)
  if !client_arch.match(/i386|sparc|x86_64/)
    puts "Warning:\tInvalid architecture specified"
    puts "Warning:\tUse -a i386, -a x86_64 or -a sparc"
    exit
  end
  return
end

# Client MAC check

def check_client_mac(client_mac)
  if !client_mac.match(/[0-9]/)
    puts "Warning:\tNo client MAC address given"
    exit
  end
  return
end

# Client IP check

def check_client_ip(client_ip)
  if !client_ip.match(/[0-9]/)
    puts "Warning:\tNo client IP address given"
    exit
  end
  return
end

# Add apache proxy

def add_apache_proxy(publisher_host,publisher_port,service_base_name)
  apache_config_file = "/etc/apache2/2.2/httpd.conf"
  apache_check=%x[cat #{apache_config_file} |grep #{service_base_name}]
  if !apache_check.match(/#{service_base_name}/)
    message = "Archiving:\t"+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(message,command)
    message = "Adding:\t\tProxy entry to "+apache_config_file
    command = "echo 'ProxyPass /"+service_base_name+" http://"+publisher_host+":"+publisher_port+" nocanon max=200' >>"+apache_config_file
    execute_command(message,command)
    smf_service_name = "apache22"
    enable_smf_service(smf_service_name)
    refresh_smf_service(smf_service_name)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  apache_config_file="/etc/apache2/2.2/httpd.conf"
  message="Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command="cat #{apache_config_file} |grep '#{service_base_name}'"
  apache_check=execute_command(message,command)
  if apache_check.match(/#{service_base_name}/)
    restore_file=apache_config_file+".no_"+service_base_name
    if File.exists?(restore_file)
      message="Restoring:\t"+restore_file+" to "+apache_config_file
      command="cp #{restore_file} #{apache_config_file}"
      execute_command(message,command)
      smf_service_name="apache22"
      refresh_smf_service(smf_service_name)
    end
  end
end

# Add apache alias

def add_apache_alias(service_base_name)
  repo_version_dir=$repo_base_dir+"/"+service_base_name
  apache_config_file="/etc/apache2/2.2/httpd.conf"
  message      = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command      = "cat #{apache_config_file} |grep '#{service_base_name}'"
  apache_check = execute_command(message,command)
  if !apache_check.match(/#{service_base_name}/)
    message = "Archiving:\t"+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(message,command)
    if $verbose_mode == 1
      puts "Adding:\t\tDirectory and Alias entry to "+apache_config_file
    end
    output=File.open(apache_config_file,"a")
    output.write("Alias /#{service_base_name} #{repo_version_dir}")
    output.write("<Directory #{repo_version_dir}>\n")
    output.write("Options Indexes\n")
    output.write("Allow from #{$default_apache_allow}\n")
    output.write("</Directory>\n")
    output.close
    smf_service_name = "apache22"
    enable_smf_service(smf_service_name)
    refresh_smf_service(smf_service_name)
  end
  return
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(iso_file)
  puts "Processing:\t"+iso_file
  output  = check_dir_exists($iso_mount_dir)
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $1}' |grep '^#{$iso_mount_dir}$'"
  output=execute_command(message,command)
  if output.match(/[A-z]/)
    message = "Unmounting:\t"+$iso_mount_dir
    command = "umount "+$iso_mount_dir
    output  = execute_command(message,command)
  end
  message = "Mounting:\tISO "+iso_file+" on "+$iso_mount_dir
  command = "mount -F hsfs "+iso_file+" "+$iso_mount_dir
  output  = execute_command(message,command)
  if iso_file.match(/sol/)
    if iso_file.match(/\-ga\-/)
      iso_test_dir = $iso_mount_dir+"/boot"
    else
      iso_test_dir = $iso_mount_dir+"/repo"
    end
  else
    if iso_file.match(/CentOS/)
      iso_test_dir = $iso_mount_dir+"/CentOS"
    else
      if iso_file.match(/rhel/)
        iso_test_dir = $iso_mount_dir+"/Packages"
      else
        if iso_file.match(/VM/)
          iso_test_dir = $iso_mount_dir+"/upgrade"
        else
          iso_test_dir = $iso_mount_dir+"/install"
        end
      end
    end
  end
  if !File.directory?(iso_test_dir)
    puts "Warning:\tISO did not mount, or this is not a repository ISO"
    puts "Warning:\t"+iso_test_dir+" does not exit"
    if $test_mode != 1
      exit
    end
  end
  return
end

# Copy repository from ISO to local filesystem

def copy_iso(iso_file,repo_version_dir)
  puts "Checking:\tIf we can copy data from full repo ISO"
  if iso_file.match(/sol/)
    iso_repo_dir = $iso_mount_dir+"/repo"
    test_dir     = repo_version_dir+"/publisher"
  else
    iso_repo_dir = $iso_mount_dir
    if iso_file.match(/CentOS|rhel/)
      test_dir     = repo_version_dir+"/isolinux"
    else
      if iso_file.match(/VM/)
        test_dir     = repo_version_dir+"/upgrade"
      else
        test_dir     = repo_version_dir+"/install"
      end
    end
  end
  if !File.directory?(repo_version_dir)
    puts "Warning:\tRepository directory "+repo_version_dir+" does not exist"
    if $test_mode != 1
      exit
    end
  end
  if !File.directory?(test_dir)
    if iso_file.match(/sol/)
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      output  = execute_command(message,command)
      message = "Rebuilding:\tRepository in "+repo_version_dir
      command = "pkgrepo -s #{repo_version_dir} rebuild"
      output  = execute_command(message,command)
    else
      check_dir_exists(test_dir)
      message = "Copying:\t"+iso_repo_dir+" contents to "+repo_version_dir
      command = "rsync -a #{iso_repo_dir}/* #{repo_version_dir}"
      output  = execute_command(message,command)
    end
  end
  return
end

# Unmount ISO

def umount_iso()
  message = "Unmounting:\tISO mounted on"+$iso_mount_dir
  command = "umount #{$iso_mount_dir}"
  execute_command(message,command)
  return
end
