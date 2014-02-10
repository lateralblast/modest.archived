# Solaris common code

# Handle SMF service

def handle_smf_service(function,smf_service_name)
  if $os_name.match(/SunOS/)
    uc_function = function.capitalize
    if function.match(/enable/)
      message = "Checking:\tStatus of service "+smf_service_name
      command = "svcs #{smf_service_name} |grep -v STATE"
      output  = execute_command(message,command)
      if output.match(/maintenance/)
        message = uc_function+":\tService "+smf_service_name
        command = "svcadm clear #{smf_service_name} ; sleep 5"
        output  = execute_command(message,command)
      end
      if !output.match(/online/)
        message = uc_function+":\tService "+smf_service_name
        command = "svcadm #{function} #{smf_service_name} ; sleep 5"
        output  = execute_command(message,command)
      end
    else
      message = uc_function+":\tService "+smf_service_name
      command = "svcadm #{function} #{smf_service_name} ; sleep 5"
      output  = execute_command(message,command)
    end
  end
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
  if $os_name.match(/SunOS/)
    message = "Checking:\tService "+smf_service_name
    command = "svcs -a |grep '#{smf_service_name}"
    output  = execute_command(message,command)
  end
  return output
end


# Check Solaris 11 package

def install_sol11_pkg(pkg_name)
  message = "Checking:\tPackage "+pkg_name+" is installed"
  command = "pkg info #{pkg_name} | grep 'Name:' |awk '{print $3}'"
  output  = execute_command(message,command)
  if output.match(/#{pkg_name}/)
    message = "Installing:\tPackage "+pkg_name
    command = "pkg install #{pkg_name}"
    execute_command(message,command)
  end
  return
end

# Check Solaris 11 NTP

def check_sol11_ntp()
  ntp_file = "/etc/inet/ntp.conf"
  [0..3].each do |number|
    ntp_host = number+"."+$default_country.downcase+".ntp.pool.org"
    message  = "Checking:\tNTP server "+ntp_host+" is in "+ntp_file
    command  = "cat #{ntp_file} | grep '#{ntp_host}'"
    output   = execute_command(message,command)
    ntp_test = output.chomp
    if !ntp_test.match(/#ntp_test/)
      message = "Adding:\tNTP host "+ntp_host+" to "+ntp_file
      ommand  = "echo '#{ntp_host}' >> #{ntp_file}"
      execute_command(message,command)
    end
  end
  ["driftfile /var/ntp/ntp.drift","statsdir /var/ntp/ntpstats/",
    "filegen peerstats file peerstats type day enable",
   "filegen loopstats file loopstats type day enable"].each do |ntp_entry|
    message  = "Checking:\tNTP entry "+ntp_entry+" is in "+ntp_file
    command  = "cat #{ntp_file} | grep '#{ntp_entry}'"
    output   = execute_command(message,command)
    ntp_test = output.chomp
    if !ntp_test.match(/#{ntp_entry}/)
      message = "Adding:\tNTP entry "+ntp_entry+" to "+ntp_file
      ommand  = "echo '#{ntp_entry}' >> #{ntp_file}"
      execute_command(message,command)
    end
  end
  enable_smf_service(smf_service_name)
  return
end


# Create named configuration file

def create_named_conf()
  named_conf = "/etc/named.conf"
  tmp_file   = "/tmp/named_conf"
  if !File.exists(named_conf)
    file = File.open(tmp_file)
    file.write("\n")
    file.write("# named config\n")
    file.write("\n")
    file.write("options {\n")
    file.write("  directory \"/etc/namedb/working\";\n")
    file.write("  pid-file  \"/var/run/named/pid\";\n")
    file.write("  dump-file \"/var/dump/named_dump.db\";\n")
    file.write("  statistics-file \"/var/stats/named.stats\";\n")
    file.write("  forwarders  {#{$default_nameserver}};\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"local\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/local.db\"\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"1.168.192.in-addr.arpa\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/1.168.192.db\";\n")
    file.write("};\n")
    file.write("\n")
    file.write("\n")
    file.close
    message = "Creating:\tDirectories for named"
    command = "mkdir /var/dump ; mkdir /var/stats ; mkdir -p /var/run/namedb ; mkdir -p /etc/namedb/master ; mkdir -p /etc/namedb/working"
    execute_command(message,command)
  end
  return
end

# Check Solaris DNS server

def check_sol_bind()
  if $os_name.match(/11/)
    pkg_name = "service/network/dns/bind"
    install_sol11_pkg(pkg_name)
  end
  create_named_conf()
  return
end
