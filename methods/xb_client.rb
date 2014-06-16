# Code for *BSD and other PXE clients (e.g. CoreOS)

# List BSD clients

def list_xb_clients()
  return
end

# Configure client PXE boot

def configure_xb_pxe_client(client_name,client_ip,client_mac,client_arch,service_name,publisher_host)
  os_version    = service_name.split(/_/)[1..2].join(".")
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tmp_file      = "/tmp/pxecfg"
  if service_name.match(/openbsd/)
    tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    pxeboot_file  = service_name+"/"+os_version+"/"+client_arch.gsub(/x86_64/,"amd64")+"/pxeboot"
  else
    tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    pxeboot_file  = service_name+"/isolinux/pxelinux.0"
  end
  if File.symlink?(test_file)
    message = "Removing:\tOld PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(message,command)
  end
  message = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
  command = "cd #{$tftp_dir} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(message,command)
  if service_name.match(/coreos/)
    ldlinux_file = $tftp_dir+"/"+service_name+"/isolinux/ldlinux.c32"
    ldlinux_link = $tftp_dir+"/ldlinux.c32"
    if !File.exist?(ldlinux_link)
      message = "Copying:\tFile #{ldlinux_file} #{ldlinux_link}"
      command = "cp #{ldlinux_file} #{ldlinux_link}"
      execute_command(message,command)
    end
    client_dir   = $client_base_dir+"/"+service_name+"/"+client_name
    client_file  = client_dir+"/"+client_name+".yml"
    client_url   = "http://"+publisher_host+"/clients/"+service_name+"/"+client_name+"/"+client_name+".yml"
    pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
    pxe_cfg_file = client_mac.gsub(/:/,"-")
    pxe_cfg_file = "01-"+pxe_cfg_file
    pxe_cfg_file = pxe_cfg_file.downcase
    pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
    vmlinuz_file = "/"+service_name+"/coreos/vmlinuz"
    initrd_file  = "/"+service_name+"/coreos/cpio.gz"
    file         = File.open(tmp_file,"w")
    file.write("default coreos\n")
    file.write("prompt 1\n")
    file.write("timeout 3\n")
    file.write("label coreos\n")
    file.write("  menu default\n")
    file.write("  kernel #{vmlinuz_file}\n")
    file.write("  append initrd=#{initrd_file} cloud-config-url=#{client_url}\n")
    file.close
    message = "Creating:\tPXE configuration file "+pxe_cfg_file
    command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
    execute_command(message,command)
    print_contents_of_file(pxe_cfg_file)
  end
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

# Output CoreOS client configuration file

def output_coreos_client_profile(client_name,service_name)
  client_dir = $client_base_dir+"/"+service_name+"/"+client_name
  check_dir_exists(client_dir)
  output_file  = client_dir+"/"+client_name+".yml"
  root_crypt   = $q_struct["root_crypt"].value
  admin_group  = $q_struct["admin_group"].value
  admin_user   = $q_struct["admin_user"].value
  admin_crypt  = $q_struct["admin_crypt"].value
  admin_home   = $q_struct["admin_home"].value
  admin_uid    = $q_struct["admin_uid"].value
  admin_gid    = $q_struct["admin_gid"].value
  client_ip    = $q_struct["ip"].value
  client_nic   = $q_struct["nic"].value
  network_ip   = client_ip.split(".")[0..2].join(".")+".0"
  broadcast_ip = client_ip.split(".")[0..2].join(".")+".255"
  gateway_ip   = client_ip.split(".")[0..2].join(".")+".254"
  file = File.open(output_file,"w")
  file.write("\n")
  file.write("network-interfaces: |\n")
  file.write("  iface #{client_nic} inet static\n")
  file.write("  address #{client_ip}\n")
  file.write("  network #{network_ip}\n")
  file.write("  netmask #{$default_netmask}\n")
  file.write("  broadcast #{broadcast_ip}\n")
  file.write("  gateway #{gateway_ip}\n")
  file.write("\n")
  file.write("hostname: #{client_name}\n")
  file.write("\n")
  file.write("users:\n")
  file.write("  - name: root\n")
  file.write("    passwd: #{root_crypt}\n")
  file.write("  - name: #{admin_user}\n")
  file.write("    passwd: #{admin_crypt}\n")
  file.write("    groups: sudo\n")
  file.write("\n")
  return output_file
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
  if service_name.match(/coreos/)
    populate_coreos_questions(service_name,client_name,client_ip)
    process_questions(service_name)
    output_coreos_client_profile(client_name,service_name)
  end
  configure_xb_pxe_client(client_name,client_ip,client_mac,client_arch,service_name,publisher_host)
  configure_xb_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  add_hosts_entry(client_name,client_ip)
  return
end
