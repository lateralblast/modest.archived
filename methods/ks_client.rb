
# Kickstart client routines

def unconfigure_ks_client(client_name,client_mac,service_name)
  unconfigure_ks_pxe_client(client_name)
  unconfigure_ks_dhcp_client(client_name)
  return
end

# Unconfigure client PXE boot

def unconfigure_ks_pxe_client(client_name)
  client_mac=get_client_mac(client_name)
  tftp_pxe_file=client_mac.gsub(/:/,"")
  tftp_pxe_file=tftp_pxe_file.upcase
  tftp_pxe_file="01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file=$tftp_dir+"/"+tftp_pxe_file
  if File.exists?(tftp_pxe_file)
    message="Removing:\tPXE boot file "+tftp_pxe_file+" for "+client_name
    command="rm #{tftp_pxe_file}"
    output=execute_command(message,command)
  end
  pxe_cfg_dir=$tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file=client_mac.gsub(/:/,"-")
  pxe_cfg_file="01-"+pxe_cfg_file
  pxe_cfg_file=pxe_cfg_file.downcase
  pxe_cfg_file=pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exists?(pxe_cfg_file)
    message="Removing:\tPXE boot config file "+pxe_cfg_file+" for "+client_name
    command="rm #{pxe_cfg_file}"
    output=execute_command(message,command)
  end
  unconfigure_ks_dhcp_client(client_name)
  return
end

# Unconfigure client DHCPd

def unconfigure_ks_dhcp_client(client_name)
  dhcpd_file="/etc/inet/dhcpd4.conf"
  message="Checking:\fIf DHCPd configuration contains "+client_name
  command="cat #{dhcpd_file} | grep '#{client_name}'"
  output=execute_command(message,command)
  if output.match(/#{client_name}/)
    restore_file=dhcpd_file+".no_"+client_name
    message="Restoring:\tDHCPd config file "+restore_file+" to "+dhcpd_file
    command="cp #{restore_file} #{dhcpd_file}"
  end
  restart_dhcpd()
  return
end

# Configure client PXE boot

def configure_ks_client_pxe_boot(client_name,client_mac,service_name)
  tftp_pxe_file=client_mac.gsub(/:/,"")
  tftp_pxe_file=tftp_pxe_file.upcase
  tftp_pxe_file="01"+tftp_pxe_file+".pxelinux"
  test_file=$tftp_dir+"/"+tftp_pxe_file
  if !File.exists?(test_file)
    pxelinux_file=service_name+"/usr/share/syslinux/pxelinux.0"
    message="Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
    command="cd #{$tftp_dir} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
    output=execute_command(message,command)
  end
  pxe_cfg_dir=$tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file=client_mac.gsub(/:/,"-")
  pxe_cfg_file="01-"+pxe_cfg_file
  pxe_cfg_file=pxe_cfg_file.downcase
  pxe_cfg_file=pxe_cfg_dir+"/"+pxe_cfg_file
  vmlinuz_file="/"+service_name+"/images/pxeboot/vmlinuz"
  initrd_file="/"+service_name+"/images/pxeboot/initrd.img"
  ks_url="http://"+$default_host+"/"+service_name+"/"+client_name+".cfg"
  file=File.open(pxe_cfg_file,"w")
  file.write("DEFAULT LINUX\n")
  file.write("LABEL LINUX\n")
  file.write("  KERNEL #{vmlinuz_file}\n")
  file.write("  APPEND initrd=#{initrd_file} ks=#{ks_url}\n")
  file.close
  if $verbose_mode == 1
    puts "Created:\tPXE menu filw "+pxe_cfg_file+":"
    system("cat #{pxe_cfg_file}")
  end
  return
end

# Configure DHCP entry

def configure_ks_client_dhcp(client_name,client_mac,client_ip)
  tftp_pxe_file=client_mac.gsub(/:/,"")
  tftp_pxe_file=tftp_pxe_file.upcase
  tftp_pxe_file="01"+tftp_pxe_file+".pxelinux"
  dhcpd_file="/etc/inet/dhcpd4.conf"
  message="Checking:\fIf DHCPd configuration contains "+client_name
  command="cat #{dhcpd_file} | grep '#{client_name}'"
  output=execute_command(message,command)
  if !output.match(/#{client_name}/)
    backup_file=dhcpd_file+".no_"+client_name
    message="Archiving:\tDHCPd config file "+dhcpd_file+" to "+backup_file
    command="cp #{dhcpd_file} #{backup_file}"
    file=File.open(dhcpd_file,"a")
    file.write("\n")
    file.write("host #{client_name} {\n")
    file.write("  fixed-address #{client_ip};\n")
    file.write("  hardware ethernet #{client_mac};\n")
    file.write("  filename \"#{tftp_pxe_file}\";\n")
    file.write("}\n")
    file.close
  end
  restart_dhcpd()
  return
end

# Configure client

def configure_ks_client(client_name,client_arch,client_mac,client_ip,service_name)
  repo_version_dir=$repo_base_dir+"/"+service_name
  (q_struct,q_order)=populate_ks_questions(service_name,client_name,client_ip)
  process_questions(q_struct,q_order)
  output_file=repo_version_dir+"/"+client_name+".cfg"
  if File.exists?(output_file)
    File.delete(output_file)
  end
  output_ks_header(q_struct,q_order,output_file)
  pkg_list=populate_ks_pkg_list()
  output_ks_pkg_list(pkg_list,output_file)
  post_list=populate_ks_post_list(q_struct,service_name)
  output_ks_post_list(post_list,output_file)
#  post_list=populate_ks_post_list()
#  output_ks_post_list(post_list,output_file)
  if output_file
    FileUtils.chmod(0755,output_file)
  end
  configure_ks_client_pxeboot(client_name,client_mac,service_name)
  configure_ks_client_dhcp(client_name,client_mac,client_ip)
  return
end

# Populate post commands

def populate_ks_post_list(q_struct,service_name)
  post_list=[]
  admin_group=q_struct["admingroup"].value
  admin_user=q_struct["adminuser"].value
  admin_crypt=q_struct["admincrypt"].value
  admin_home=q_struct["adminhome"].value
  post_list.push("groupadd #{admin_group}")
  post_list.push("groupadd #{admin_user}")
  post_list.push("useradd -p #{admin_crypt} -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
  post_list.push("echo \"#{admin_user}\tALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
  if $use_alt_repo == 1
    post_list.push("mkdir /tmp/rpms")
    post_list.push("cd /tmp/rpms")
    alt_url="http://"+$default_host
    rpm_list=build_ks_alt_rpm_list(service_name)
    alt_dir=$repo_base_dir+"/"+service_name+"/alt"
    if $verbose_mode == 1
      puts "Checking:\tAdditional packages"
    end
    if File.directory?(alt_dir)
      rpm_list.each do |rpm_url|
        rpm_file=File.basename(rpm_url)
        rpm_file=alt_dir+"/"+rpm_file
        rpm_url=alt_url+"/"+rpm_file
        if File.exists?(rpm_file)
          post_list.push("wget #{rpm_url}")
        end
      end
    end
    post_list.push("rpm -i *.rpm")
    post_list.push("cd /tmp")
    post_list.push("rm -rf /tmp/rpms")
  end
  post_list.push("")
  return post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list()
  pkg_list=[]
  pkg_list.push("@ core")
  pkg_list.push("grub")
  pkg_list.push("e2fsprogs")
  pkg_list.push("lvm2")
  pkg_list.push("kernel-devel")
  pkg_list.push("kernel-headers")
  pkg_list.push("libselinux-ruby")
  pkg_list.push("tk")
  return pkg_list
end

# Output the Kickstart file header

def output_ks_header(q_struct,q_order,output_file)
  if $verbose_mode == 1
    puts "Creating:\tKickstart file "+output_file
  end
  file=File.open(output_file, 'a')
  q_order.each do |key|
    if q_struct[key].type == "output"
      if q_struct[key].parameter == ""
        output=q_struct[key].value+"\n"
      else
        output=q_struct[key].parameter+" "+q_struct[key].value+"\n"
      end
      file.write(output)
    end
  end
  file.close
  return
end

# Output the ks packages list

def output_ks_pkg_list(pkg_list,output_file)
  file=File.open(output_file, 'a')
  output="\n%packages\n"
  file.write(output)
  pkg_list.each do |pkg_name|
    output=pkg_name+"\n"
    file.write(output)
  end
  file.close
  return
end

# Output the ks packages list

def output_ks_post_list(post_list,output_file)
  file=File.open(output_file, 'a')
  output="\n%post\n"
  file.write(output)
  post_list.each do |line|
    output=line+"\n"
    file.write(output)
  end
  file.close
  return
end

# List ks clients

def list_ks_clients()
  puts "Kickstart clients:"
  service_list=Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/centos|redhat/)
      repo_version_dir=$repo_base_dir+"/"+service_name
      client_list=Dir.entries(repo_version_dir)
      client_list.each do |client_name|
        if client_name.match(/\.cfg$/)
          puts client_name+" service = "+service_name
        end
      end
    end
  end
  return
  return
end

# Check service service_name

def check_ks_service_name(service_name)
  if !service_name.match(/[A-z]/)
    puts "Warning:\tService name not given"
    exit
  end
  client_list=Dir.entries($repo_base_dir)
  if !client_list.grep(service_name)
    puts "Warning:\tService name "+service_name+" does not exist"
    exit
  end
  return
end
