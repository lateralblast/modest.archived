
# Common routines for server and client configuration

# Question/config structure

Ai=Struct.new(:question, :ask, :value, :valid, :eval)

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_ai_repo_version(publisher_url,publisher_host,publisher_port)
  publisher_url = get_ai_publisher_url(publisher_host,publisher_port)
  if $test_mode == 1 or $os_name.match(/Darwin/)
  repo_version  = "0.175.1"
  else
    message      = "Determining:\tIf available repository version from "+publisher_url
    command      = "pkg info -g #{publisher_url} entire |grep Branch |awk '{print $2}'"
    repo_version = execute_command(message,command)
    repo_version = repo_version.chomp
    repo_version = repo_version.split(/\./)[0..2].join(".")
  end
  return repo_version
end

# Check the publisher port isn't being used

def check_publisher_port(publisher_port)
  message      = "Determining:\tIf publisher port "+publisher_port+" is in use"
  command      = "svcprop -a pkg/server |grep 'port count'"
  ports_in_use = execute_command(message,command)
  if ports_in_use.match(/#{publisher_port}/)
    if $verbose_mode == 1
      puts "Warning:\tPublisher port "+publisher_port+" is in use"
      puts "Finding:\tFree publisher port"
    end
  end
  while ports_in_use.match(/#{publisher_port}/)
    publisher_port = publisher_port.to_i+1
    publisher_port = publisher_port.to_s
  end
  if $verbose_mode == 1
    puts "Setting:\tPublisher port to "+publisher_port
  end
  return publisher_port
end

# Get publisher port for service

def get_publisher_port(service_name)
  message     = "Determining:\tPublisher port for service "+service_name
  command     = "svcprop -a pkg/server |grep 'port count'"
  port_in_use = execute_command(message,command)
  return port_in_use
end

# Get the repository URL

def get_ai_repo_url(publisher_url,publisher_host,publisher_port)
  repo_version = get_ai_repo_version(publisher_url,publisher_host,publisher_port)
  repo_url     = "pkg:/entire@0.5.11-"+repo_version
  return repo_url
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_ai_publisher_url(publisher_host,publisher_port)
  publisher_url = "http://"+publisher_host+":"+publisher_port
  return publisher_url
end

# Get alternate publisher url

def get_ai_alt_publisher_url(publisher_host,publisher_port)
  publisher_port = publisher_port.to_i+1
  publisher_port = publisher_port.to_s
  publisher_url  = "http://"+publisher_host+":"+publisher_port
  return publisher_url
end

# Get service base name

def get_ai_service_base_name(service_name)
  service_base_name = service_name
  if service_base_name.match(/i386|sparc/)
    service_base_name = service_base_name.gsub(/i386/,"")
    service_base_name = service_base_name.gsub(/sparc/,"")
    service_base_name = service_base_name.gsub(/_$/,"")
  end
  return service_base_name
end

# Configure a package repository

def configure_ai_pkg_repo(publisher_host,publisher_port,service_name,repo_version_dir,read_only)
  if $os_name.match(/SunOS/)
    smf_name = "pkg/server:#{service_name}"
    message  = "Checking:\tIf service "+smf_name+" exists"
    if service_name.match(/alt/)
      command = "svcs -a |grep '#{smf_name}"
    else
      command = "svcs -a |grep '#{smf_name} |grep -v alt"
    end
    output = execute_command(message,command)
    if !output.match(/#{smf_name}/)
      message  = ""
      commands = []
      commands.push("svccfg -s pkg/server add #{service_name}")
      commands.push("svccfg -s #{smf_name} addpg pkg application")
      commands.push("svccfg -s #{smf_name} setprop pkg/port=#{publisher_port}")
      commands.push("svccfg -s #{smf_name} setprop pkg/inst_root=#{repo_version_dir}")
      commands.push("svccfg -s #{smf_name} addpg general framework")
      commands.push("svccfg -s #{smf_name} addpropvalue general/complete astring: #{service_name}")
      commands.push("svccfg -s #{smf_name} setprop pkg/readonly=#{read_only}")
      commands.push("svccfg -s #{smf_name} setprop pkg/proxy_base = astring: http://#{publisher_host}/#{service_name}")
      commands.push("svccfg -s #{smf_name} addpropvalue general/enabled boolean: true")
      commands.each do |temp_command|
        execute_command(message,temp_command)
      end
      refresh_smf_service(smf_name)
      add_apache_proxy(publisher_host,publisher_port,service_name)
    end
  end
  return
end

# Delete a package repository

def unconfigure_ai_pkg_repo(smf_service_name)
  service_name = smf_service_name.split(":")[1]
  if $os_name.match(/SunOS/)
    message  = "Checking:\tIf repository service "+smf_service_name+" exists"
    if smf_service_name.match(/alt/)
      command  = "svcs -a |grep '#{smf_service_name}'"
    else
      command  = "svcs -a |grep '#{smf_service_name}' |grep -v alt"
    end
    output   = execute_command(message,command)
    if output.match(/#{smf_service_name}/)
      disable_smf_service(smf_service_name)
      message = "Removing\tPackage repository service "+smf_service_name
      command = "svccfg -s pkg/server delete #{smf_service_name}"
      execute_command(message,command)
      remove_apache_proxy(service_name)
    end
  end
  return
end

