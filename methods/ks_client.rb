
# Kickstart client routines

# List ks clients

def list_ks_clients()
  puts "Kickstart clients:"
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/centos|redhat/)
      repo_version_dir = $repo_base_dir+"/"+service_name
      client_list      = Dir.entries(repo_version_dir)
      client_list.each do |client_name|
        if client_name.match(/\.cfg$/)
          puts client_name+" service = "+service_name
        end
      end
    end
  end
  return
end

# Configure client PXE boot

def configure_ks_pxe_client(client_name,client_mac,service_name)
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  test_file     = $tftp_dir+"/"+tftp_pxe_file
  if !File.exists?(test_file)
    if service_name.match(/ubuntu/)
      pxelinux_file = service_name+"/images/pxeboot/netboot/pxelinux.0"
    else
      pxelinux_file = service_name+"/usr/share/syslinux/pxelinux.0"
    end
    message       = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
    command       = "cd #{$tftp_dir} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
    execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = client_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  vmlinuz_file = "/"+service_name+"/images/pxeboot/vmlinuz"
  if service_name.match(/ubuntu/)
    if service_name.match(/x86_64/)
      initrd_file  = "/"+service_name+"/images/pxeboot/netboot/ubuntu-installer/amd64/initrd.gz"
    else
      initrd_file  = "/"+service_name+"/images/pxeboot/netboot/ubuntu-installer/i386/initrd.gz"
    end
  else
    initrd_file  = "/"+service_name+"/images/pxeboot/initrd.img"
  end
  ks_url       = "http://"+$default_host+"/"+service_name+"/"+client_name+".cfg"
  file         = File.open(pxe_cfg_file,"w")
  file.write("DEFAULT LINUX\n")
  file.write("LABEL LINUX\n")
  file.write("  KERNEL #{vmlinuz_file}\n")
  if service_name.match(/ubuntu/)
    append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{client_name} initrd=#{initrd_file}"
  else
    append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url}"
  end
  if $text_install == 1
    append_string = append_string+" text"
    if $use_serial == 1
      append_string = append_string+" serial console=ttyS0"
    end
  end
  append_string = append_string+"\n"
  file.write(append_string)
  file.close
  if $verbose_mode == 1
    puts "Created:\tPXE menu file "+pxe_cfg_file+":"
    system("cat #{pxe_cfg_file}")
  end
  return
end

# Unconfigure client PXE boot

def unconfigure_ks_pxe_client(client_name)
  client_mac=get_client_mac(client_name)
  if !client_mac
    puts "Warning:\tNo MAC Address entry found for "+client_name
    exit
  end
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exists?(tftp_pxe_file)
    message = "Removing:\tPXE boot file "+tftp_pxe_file+" for "+client_name
    command = "rm #{tftp_pxe_file}"
    output  = execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = client_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exists?(pxe_cfg_file)
    message = "Removing:\tPXE boot config file "+pxe_cfg_file+" for "+client_name
    command = "rm #{pxe_cfg_file}"
    output  = execute_command(message,command)
  end
  unconfigure_ks_dhcp_client(client_name)
  return
end

# Configure DHCP entry

def configure_ks_dhcp_client(client_name,client_mac,client_ip,service_name)
  add_dhcp_client(client_name,client_mac,client_ip,service_name)
  return
end

# Unconfigure DHCP client

def unconfigure_ks_dhcp_client(client_name)
  remove_dhcp_client(client_name)
  return
end

# Configure Kickstart client

def configure_ks_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  repo_version_dir = $repo_base_dir+"/"+service_name
  if !File.directory?(repo_version_dir)
    puts "Warning:\tService "+service_name+" does not exist"
    puts
    list_ks_services()
    exit
  end
  output_file = repo_version_dir+"/"+client_name+".cfg"
  if File.exists?(output_file)
    File.delete(output_file)
  end
  if service_name.match(/rhel|centos/)
    populate_ks_questions(service_name,client_name,client_ip)
    process_questions()
    output_ks_header(output_file)
    pkg_list  = populate_ks_pkg_list(service_name)
    output_ks_pkg_list(pkg_list,output_file)
    post_list = populate_ks_post_list(service_name)
    output_ks_post_list(post_list,output_file,service_name)
  else
    populate_ps_questions(service_name,client_name,client_ip)
    process_questions
    output_ps_header(output_file)
    output_file = repo_version_dir+"/"+client_name+"_post.sh"
    post_list   = populate_ks_post_list(service_name)
    output_ks_post_list(post_list,output_file,service_name)
  end
  configure_ks_pxe_client(client_name,client_mac,service_name)
  configure_ks_dhcp_client(client_name,client_mac,client_ip,service_name)
  return
end

# Unconfigure Kickstart client

def unconfigure_ks_client(client_name,client_mac,service_name)
  unconfigure_ks_pxe_client(client_name)
  unconfigure_ks_dhcp_client(client_name)
  return
end

# Populate post commands

def populate_ks_post_list(service_name)
  post_list   = []
  if service_name.match(/centos|rhel/)
    admin_group = $q_struct["admingroup"].value
    admin_user  = $q_struct["adminuser"].value
    admin_crypt = $q_struct["admincrypt"].value
    admin_home  = $q_struct["adminhome"].value
    post_list.push("groupadd #{admin_group}")
    post_list.push("groupadd #{admin_user}")
    post_list.push("useradd -p #{admin_crypt} -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
    post_list.push("echo \"#{admin_user}\tALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
    if $use_alt_repo == 1
      post_list.push("mkdir /tmp/rpms")
      post_list.push("cd /tmp/rpms")
      alt_url  = "http://"+$default_host
      rpm_list = build_ks_alt_rpm_list(service_name)
      alt_dir  = $repo_base_dir+"/"+service_name+"/alt"
      if $verbose_mode == 1
        puts "Checking:\tAdditional packages"
      end
      if File.directory?(alt_dir)
        rpm_list.each do |rpm_url|
          rpm_file = File.basename(rpm_url)
          rpm_file = alt_dir+"/"+rpm_file
          rpm_url  = alt_url+"/"+rpm_file
          if File.exists?(rpm_file)
            post_list.push("wget #{rpm_url}")
          end
        end
      end
      post_list.push("rpm -i *.rpm")
      post_list.push("cd /tmp")
      post_list.push("rm -rf /tmp/rpms")
    end
  else
    post_list.push("apt-get install puppet")
  end
  post_list.push("")
  return post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list(service_name)
  pkg_list = []
  if service_name.match(/centos|rhel/)
    pkg_list.push("@ core")
    pkg_list.push("grub")
    pkg_list.push("e2fsprogs")
    pkg_list.push("lvm2")
    pkg_list.push("kernel-devel")
    pkg_list.push("kernel-headers")
    pkg_list.push("libselinux-ruby")
    pkg_list.push("tk")
#    pkg_list.push("puppet")
  end
  return pkg_list
end

# Output the Preseed file contents

def output_ps_header(output_file)
  if $verbose_mode == 1
    puts "Creating:\tPreseed file "+output_file
  end
  file=File.open(output_file, 'a')
  $q_order.each do |key|
    if $q_struct[key].parameter.match(/[A-z]/)
      output = "d-i "+$q_struct[key].parameter+" "+$q_struct[key].type+" "+$q_struct[key].value+"\n"
      file.write(output)
    end
  end
  file.close
  return
end

# Output the Kickstart file header

def output_ks_header(output_file)
  if $verbose_mode == 1
    puts "Creating:\tKickstart file "+output_file
  end
  file=File.open(output_file, 'a')
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if !$q_struct[key].parameter.match(/[A-z]/)
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
      file.write(output)
    end
  end
  file.close
  return
end

# Output the ks packages list

def output_ks_pkg_list(pkg_list,output_file)
  file   = File.open(output_file, 'a')
  output = "\n%packages\n"
  file.write(output)
  pkg_list.each do |pkg_name|
    output = pkg_name+"\n"
    file.write(output)
  end
  file.close
  return
end

# Output the ks packages list

def output_ks_post_list(post_list,output_file,service_name)
  if service_name.match(/centos|rhel/)
    file=File.open(output_file, 'a')
    output = "\n%post\n"
  else
    file=File.open(output_file, 'w')
    output = "#!/bin/sh\n"
  end
  file.write(output)
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  file.close
  return
end

# Check service service_name

def check_ks_service_name(service_name)
  if !service_name.match(/[A-z]/)
    puts "Warning:\tService name not given"
    exit
  end
  client_list = Dir.entries($repo_base_dir)
  if !client_list.grep(service_name)
    puts "Warning:\tService name "+service_name+" does not exist"
    exit
  end
  return
end
