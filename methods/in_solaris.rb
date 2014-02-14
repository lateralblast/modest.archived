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
      command = "echo '#{ntp_host}' >> #{ntp_file}"
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
      command = "echo '#{ntp_entry}' >> #{ntp_file}"
      execute_command(message,command)
    end
  end
  enable_smf_service(smf_service_name)
  return
end

# Create named configuration file

def create_named_conf()
  named_conf   = "/etc/named.conf"
  tmp_file     = "/tmp/named_conf"
  forward_file = "/etc/namedb/master/local.db"
  net_info     = $default_host.split(".")
  net_address  = net_info[2]+"."+net_info[1]+"."+net_info[0]
  host_segment = $default_host.split(".")[3]
  reverse_file = "/etc/namedb/master/"+net_address+".db"
  if !File.exist?(named_conf)
    file = File.open(tmp_file,"w")
    file.write("\n")
    file.write("# named config\n")
    file.write("\n")
    file.write("options {\n")
    file.write("  directory \"/etc/namedb/working\";\n")
    file.write("  pid-file  \"/var/run/named/pid\";\n")
    file.write("  dump-file \"/var/dump/named_dump.db\";\n")
    file.write("  statistics-file \"/var/stats/named.stats\";\n")
    file.write("  forwarders  {#{$default_nameserver};};\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"local\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/local.db\";\n")
    file.write("};\n")
    file.write("\n")
    file.write("zone \"#{net_address}.in-addr.arpa\" {\n")
    file.write("  type master;\n")
    file.write("  file \"/etc/namedb/master/1.168.192.db\";\n")
    file.write("};\n")
    file.write("\n")
    file.write("\n")
    file.close
    message = "Creating:\tDirectories for named"
    command = "mkdir /var/dump ; mkdir /var/stats ; mkdir -p /var/run/namedb ; mkdir -p /etc/namedb/master ; mkdir -p /etc/namedb/working"
    execute_command(message,command)
    message = "Creating:\tNamed configuration file "+named_conf
    command = "cp #{tmp_file} #{named_conf} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(named_conf)
  end
  serial_no = %x[date +%Y%m%d].chomp+"01"
  tmp_file  = "/tmp/forward"
  if !File.exist?(forward_file)
    file = File.open(tmp_file,"w")
    file.write("$TTL 3h\n")
    file.write("@\tIN\tSOA\t#{$default_hostname}.local. local. (\n")
    file.write("\t#{serial_no}\n")
    file.write("\t28800\n")
    file.write("\t3600\n")
    file.write("\t604800\n")
    file.write("\t38400\n")
    file.write(")\n")
    file.write("\n")
    file.write("local.\tIN\tNS\t#{$default_hostname}.\n")
    file.write("#{$default_hostname}\tIN\tA\t#{$default_host}\n")
    file.write("puppet\tIN\tA\t#{$default_host}")
    file.write("\n")
    file.close
    message = "Creating:\tNamed configuration file "+forward_file
    command = "cp #{tmp_file} #{forward_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(forward_file)
  end
  tmp_file = "/tmp/reverse"
  if !File.exist?(reverse_file)
    file = File.open(tmp_file,"w")
    file.write("$TTL 3h\n")
    file.write("@\tIN\tSOA\t#{$default_hostname}.local. local. (\n")
    file.write("\t#{serial_no}\n")
    file.write("\t28800\n")
    file.write("\t3600\n")
    file.write("\t604800\n")
    file.write("\t38400\n")
    file.write(")\n")
    file.write("\n")
    file.write("\tIN\tNS\t#{$default_hostname}.local\n")
    file.write("\n")
    file.write("#{host_segment}\tIN\tPTR\t#{$default_hostname}.\n")
    file.write("#{host_segment}\tIN\tPTR\tpuppet.\n")
    file.write("\n")
    file.close
    message = "Creating:\tNamed configuration file "+reverse_file
    command = "cp #{tmp_file} #{reverse_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(reverse_file)
  end
  return
end

# Create Puppet master service manifest

def create_sol11_puppet_agent_manifest(service)
  create_sol11_puppet_manifest(service)
  return
end

# Create Puppet agent service manifest

def create_sol11_puppet_master_manifest(service)
  create_sol11_puppet_manifest(service)
  return
end

# Import SMF file

def import_smf_manifest(service,xml_file)
  message = "Importing:\tService manifest for "+service
  command = "svccfg import #{xml_file}"
  execute_command(message,command)
  return
end

# Create Solaris Puppet Manifest

def create_sol11_puppet_manifest(service)
  puppet_conf = "/etc/puppet/puppet.conf"
  tmp_file    = "/tmp/puppet_"+service
  puppet_bin  = "/var/ruby/1.8/gem_home/bin/puppet"
  xml_file    = "/var/svc/manifest/network/puppet"+service+".xml"
  xml_output  = []
  xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
  xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.declare! :DOCTYPE, :service_bundle, :SYSTEM, "/usr/share/lib/xml/dtd/service_bundle.dtd.1"
  xml.service_bundle(:type => "manifest", :name => "puppet"+service) {
    xml.service(:name => "network/puppet"+service, :type => "service", :version => "1") {
      xml.create_default_instance(:enabled => "false")
      xml.single_instance()
      xml.dependency(:name => "config_file", :grouping => "require_all", :restart_on => "none", :type => "path") {
        xml.service_fmri(:value => "file://#{puppet_conf}")
      }
      xml.dependency(:name => "loopback", :grouping => "require_all", :restart_on => "error", :type => "service") {
        xml.service_fmri(:value => "svc:/network/loopback:default")
      }
      xml.dependency(:name => "physical", :grouping => "require_all", :restart_on => "error", :type => "service") {
        xml.service_fmri(:value => "svc:/network/physical:default")
      }
      xml.dependency(:name => "fs-localk", :grouping => "require_all", :restart_on => "error", :type => "service") {
        xml.service_fmri(:value => "svc:/system/filesystem/local")
      }
      xml.exec_method(:type => "method", :name => "start", :exec => puppet_bin+" "+service, :timeout_seconds => "60")
      xml.exec_method(:type => "method", :name => "stop", :exec => ":kill", :timeout_seconds => "60")
      xml.exec_method(:type => "method", :name => "refresh", :exec => ":true", :timeout_seconds => "60")
      xml.stability(:value => "Unstable")
      xml.template {
        xml.common_name {
          xml.loctext("Puppet "+service, :"xml:lang" => "C")
        }
        xml.documentation {
          xml.manpage(:title => "puppet"+service, :section => "1")
          xml.doc_link(:name => "puppetlabs.com", :uri =>"http://puppetlabs.com/puppet/introduction")
        }
      }
    }
  }
  file=File.open(tmp_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Creating:\tPuppet "+service
  command = "cp #{tmp_file} #{xml_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file(xml_file)
  service = "puppet"+service
  import(service,xml_file)
  service = "svc:/network/"+service
  enable_smf_service(service)
  return
end

# Check Solaris Puppet packages

def check_sol_puppet()
  puppet_conf = "/etc/puppet/puppet.conf"
  puppet_bin  = "/var/ruby/1.8/gem_home/bin/puppet"
  puppet_dir  = "/var/lib/puppet"
  if !File.exist?(puppet_bin)
    message = "Installing:\tPuppet"
    command = "gem install puppet"
    execute_command(message,command)
  end
  message = "Checking:\tPuppet user exists"
  command = "cat /etc/passwd |grep '^puppet'"
  output  = execute_command(message,command)
  if !output.match(/puppet/)
    message = "Creating:\tPuppet user"
    command = "#{puppet_bin} resource group puppet ensure=present ; #{puppet_bin} resource user puppet ensure=present gid=puppet shell='/bin/false'"
    execute_command(message,command)
  end
  if !File.exist?(puppet_conf)
    message = "Creating:\tPuppet config file "+puppet_conf
    command = "#{puppet_bin} master --genconfig > #{puppet_conf}"
    execute_command(message,command)
    message = "Adding SSL Client Entry to "+puppet_conf
    command = "echo '    ssl_client_header = SSL_CLIENT_S_DN' >> #{puppet_conf}"
    execute_command(message,command)
    message = "Adding SSL Verify Entry to "+puppet_conf
    command = "echo '    ssl_client_verify_header = SSL_CLIENT_VERIFY' >> #{puppet_conf}"
    execute_command(message,command)
    message = "Creating:\tPuppet directories"
    command = "mkdir -p #{puppet_dir}/run ; chown -R puppet:puppet #{puppet_dir}"
    execute_command(message,command)
  end
  ["master","agent"].each do |service|
    message = "Checking:\tService "+service
    command = "svcs -a |grep 'puppet#{service}'"
    output  = execute_command(message,command)
    if !output.match(/#{service}/)
      eval"[create_sol11_puppet_#{service}_manifest(service)]"
    end
    if output.match(/disabled/)
      service = "svc:/network/puppet"+service
      enable_smf_service(service)
    end
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
