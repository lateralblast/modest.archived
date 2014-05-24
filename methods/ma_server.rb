# MAAS serer related functions

# Configure MAAS server components

def configure_maas_server()
  maas_url = "http://"+$default_host+"/MAAS/"
  if $os_info.match(/Ubuntu/)
    message = "Cecking:\tInstallation status of MAAS"
    command = "dpkg -l maas"
    output  = execute_command(message,command)
    if output.match(/no packages found/)
      message = "Getting:\tUbuntu release information"
      command = "lsb_release -c"
      output  = execute_command(message,command)
      if output.match(/precise/)
        message = "Enabling:\tAPT Repository - Cloud Archive"
        command = "echo '' |add-apt-repository cloud-archive:tool"
        execute_command(message,command)
      end
      message = "Installing:\tMAAS"
      command = "echo '' |apt-get install -y apt-get install maas dnsmasq debmirror"
      execute_command(message,command)
      service = "apache"
      restart_service(service)
      service = "avahi-daemon"
      restart_service(service)
      message = "Creating:\tMAAS Admin"
      command = "maas createadmin --username=#{$default_maas_admin} --email=#{$default_maas_email} --password=#{$default_mass_password}"
      execute_command(message,command)
      puts
      puts "Information:\tLog into "+maas_url+" and continue configuration"
      puts
    end
  else
    puts "Warning:\tMAAS is only supported on Ubuntu LTS"
    exit
  end
  return
end
