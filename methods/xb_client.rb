# Code for *BSD PXE clients

# List BSD clients

def list_xb_clients()
  return
end

# Configure client PXE boot

def configure_xb_pxe_client(client_name,client_ip,client_mac,client_arch,service_name)
  os_version    = service_name.split(/_/)[1..2].join(".")
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  test_file     = $tftp_dir+"/"+tftp_pxe_file
  pxeboot_file  = service_name+"/"+os_version+"/"+client_arch.gsub(/x86_64/,"amd64")+"/pxeboot"
  if File.symlink?(test_file)
    message = "Removing:\tOld PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(message,command)
  end
  message = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
  command = "cd #{$tftp_dir} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(message,command)
  return
end

# Unconfigure BSD client

def unconfigure_xb_client(client_name,client_mac,service_name)
  unconfigure_xb_pxe_client(client_name)
  unconfigure_xb_dhcp_client(client_name)
  return
end

# Configure DHCP entry

def configure_xb_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  add_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  return
end

# Unconfigure DHCP client

def unconfigure_xb_dhcp_client(client_name)
  remove_dhcp_client(client_name)
  return
end

# Unconfigure client PXE boot

def unconfigure_xb_pxe_client(client_name)
  client_mac=get_client_mac(client_name)
  if !client_mac
    puts "Warning:\tNo MAC Address entry found for "+client_name
    exit
  end
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exist?(tftp_pxe_file)
    message = "Removing:\tPXE boot file "+tftp_pxe_file+" for "+client_name
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(message,command)
  end
  unconfigure_xb_dhcp_client(client_name)
  return
end

# Configure BSD client

def configure_xb_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name,image_file)
  repo_version_dir = $repo_base_dir+"/"+service_name
  if !File.directory?(repo_version_dir)
    puts "Warning:\tService "+service_name+" does not exist"
    puts
    list_xb_services()
    exit
  end
  configure_xb_pxe_client(client_name,client_ip,client_mac,client_arch,service_name)
  configure_xb_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  add_hosts_entry(client_name,client_ip)
  return
end
