
# Kickstart client routines

# List ks clients

def list_ks_clients()
  puts "Available Kickstart clients:"
  puts
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

def configure_ks_pxe_client(client_name,client_mac,client_arch,service_name)
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  test_file     = $tftp_dir+"/"+tftp_pxe_file
  tmp_file      = "/tmp/pxecfg"
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
  if service_name.match(/sles/)
    vmlinuz_file = "/"+service_name+"/boot/#{client_arch}/loader/linux"
  else
    vmlinuz_file = "/"+service_name+"/images/pxeboot/vmlinuz"
  end
  if service_name.match(/ubuntu/)
    if service_name.match(/x86_64/)
      initrd_file  = "/"+service_name+"/images/pxeboot/netboot/ubuntu-installer/amd64/initrd.gz"
    else
      initrd_file  = "/"+service_name+"/images/pxeboot/netboot/ubuntu-installer/i386/initrd.gz"
    end
  else
    if service_name.match(/sles/)
      initrd_file  = "/"+service_name+"/boot/#{client_arch}/loader/initrd"
    else
      initrd_file  = "/"+service_name+"/images/pxeboot/initrd.img"
    end
  end
  ks_url       = "http://"+$default_host+"/"+service_name+"/"+client_name+".cfg"
  autoyast_url = "http://"+$default_host+"/"+service_name+"/"+client_name+".xml"
  install_url  = "http://"+$default_host+"/"+service_name
  file         = File.open(tmp_file,"w")
  file.write("DEFAULT LINUX\n")
  file.write("LABEL LINUX\n")
  file.write("  KERNEL #{vmlinuz_file}\n")
  if service_name.match(/ubuntu/)
    append_string = "  APPEND auto=true priority=critical preseed/url=#{ks_url} console-keymaps-at/keymap=us locale=en_US hostname=#{client_name} initrd=#{initrd_file}"
  else
    if service_name.match(/sles/)
      append_string = "  APPEND initrd=#{initrd_file} install=#{install_url} autoyast=#{autoyast_url} language=#{$default_language}"
    else
      append_string = "  APPEND initrd=#{initrd_file} ks=#{ks_url}"
    end
  end
  if $text_install == 1
    if service_name.match(/sles/)
      append_string = append_string+" textmode=1"
    else
      append_string = append_string+" text"
    end
    if $use_serial == 1
      append_string = append_string+" serial console=ttyS0"
    end
  end
  append_string = append_string+"\n"
  file.write(append_string)
  file.close
  message = "Creating:\tPXE configuration file "+pxe_cfg_file
  command = "cp #{tmp_file} #{pxe_cfg_file} ; rm #{tmp_file}"
  execute_command(message,command)
  if $verbose_mode == 1
    puts "Information:\tPXE menu file "+pxe_cfg_file+" contents:"
    puts
    system("cat #{pxe_cfg_file}")
    puts
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

def configure_ks_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  add_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
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
  if service_name.match(/sles/)
    output_file = repo_version_dir+"/"+client_name+".xml"
  else
    output_file = repo_version_dir+"/"+client_name+".cfg"
  end
  if File.exists?(output_file)
    File.delete(output_file)
  end
  if service_name.match(/rhel|centos|sl_|oel/)
    populate_ks_questions(service_name,client_name,client_ip)
    process_questions()
    output_ks_header(output_file)
    pkg_list  = populate_ks_pkg_list(service_name)
    output_ks_pkg_list(pkg_list,output_file)
    post_list = populate_ks_post_list(client_arch,service_name,publisher_host)
    output_ks_post_list(post_list,output_file,service_name)
  else
    if service_name.match(/sles/)
      populate_ks_questions(service_name,client_name,client_ip)
      process_questions()
      output_ay_client_profile(client_name,client_ip,client_mac,output_file)
    else
      if service_name.match(/ubuntu/)
        populate_ps_questions(service_name,client_name,client_ip)
        process_questions
        output_ps_header(output_file)
        output_file = repo_version_dir+"/"+client_name+"_post.sh"
        post_list   = populate_ps_post_list()
        output_ks_post_list(post_list,output_file,service_name)
      end
    end
  end
  configure_ks_pxe_client(client_name,client_mac,client_arch,service_name)
  configure_ks_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  return
end

# Unconfigure Kickstart client

def unconfigure_ks_client(client_name,client_mac,service_name)
  unconfigure_ks_pxe_client(client_name)
  unconfigure_ks_dhcp_client(client_name)
  return
end

# Populate post commands

def populate_ks_post_list(client_arch,service_name,publisher_host)
  post_list   = []
  admin_group = $q_struct["admingroup"].value
  admin_user  = $q_struct["adminuser"].value
  admin_crypt = $q_struct["admincrypt"].value
  admin_home  = $q_struct["adminhome"].value
  epel_file   = "/etc/yum.repos.d/epel.repo"
  post_list.push("# Add Admin user")
  post_list.push("")
  post_list.push("groupadd #{admin_group}")
  post_list.push("groupadd #{admin_user}")
  post_list.push("")
  post_list.push("# Add admin user")
  post_list.push("")
  post_list.push("useradd -p '#{admin_crypt}' -g #{admin_user} -G #{admin_group} -d #{admin_home} -m #{admin_user}")
  post_list.push("")
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user}\tALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers")
  post_list.push("")
  if service_name.match(/centos|rhel|sl_|oel/)
    if service_name.match(/centos_5|rhel_5|sl_5|oel_5/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
    end
    if service_name.match(/centos_6|rhel_6|sl_6|oel_6/)
      epel_url = "http://"+$local_epel_mirror+"/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
    end
    if service_name.match(/centos/)
      repo_file = "/etc/yum.repos.d/CentOS-Base.repo"
    end
    if service_name.match(/sl_/)
      repo_file = "/etc/yum.repos.d/sl.repo"
    end
  end
  post_list.push("# Change mirror for yum")
  post_list.push("")
  post_list.push("echo 'Changing default mirror for yum'")
  post_list.push("cp #{repo_file} #{repo_file}.orig")
  if service_name.match(/centos/)
    post_list.push("sed -i 's/^mirror./#&/g' #{repo_file}")
    post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
    post_list.push("sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror},g' #{repo_file}")
  end
  if service_name.match(/sl_/)
    post_list.push("sed -i 's,#{$default_sl_mirror},#{$local_sl_mirror},g' #{repo_file}")
  end
  post_list.push("")
  post_list.push("# Configure Epel repo")
  post_list.push("")
  post_list.push("rpm -i #{epel_url}")
  post_list.push("sed -i 's/^mirror./#&/g' #{epel_file}")
  post_list.push("sed -i 's/^#\\(baseurl\\)/\\1/g' #{epel_file}")
  post_list.push("sed -i 's,#{$default_epel_mirror},#{$local_epel_mirror},g' #{epel_file}")
  post_list.push("yum -y update")
  if service_name.match(/sl_/)
    post_list.push("yum -y install redhat-lsb-core")
  end
  post_list.push("yum -y install nss-mdns")
  post_list.push("yum -y install puppet")
  post_list.push("")
  post_list.push("chkconfig avahi-daemon on")
  post_list.push("service avahi-daemon start")
  post_list.push("")
  post_list.push("# Install VM tools")
  post_list.push("")
  post_list.push("export OSREL=`lsb_release -r |awk '{print $2}' |cut -f1 -d'.'`")
  post_list.push("export OSARCH=`uname -p`")
  post_list.push("if [ \"`dmidecode |grep VMware`\" ]; then")
  post_list.push("  echo 'Installing VMware RPMs'")
  post_list.push("  echo -e \"[vmware-tools]\\nname=VMware Tools\\nbaseurl=http://#{publisher_host}/#{service_name}vmware\\nenabled=1\\ngpgcheck=0\" >> /etc/yum.repos.d/vmware-tools.repo")
  post_list.push("  yum -y install vmware-tools-core")
  post_list.push("fi")
  post_list.push("")
  post_list.push("# Enable serial console")
  post_list.push("")
  post_list.push("sed -i 's/9600/115200/' /etc/inittab")
  post_list.push("sed -i 's/kernel.*/& console=ttyS0,115200n8/' /etc/grub.conf")
  post_list.push("")
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
  post_list.push("")
  return post_list
end

# Populat a list of additional packages to install

def populate_ks_pkg_list(service_name)
  pkg_list = []
  if service_name.match(/centos|rhel|sl_|oel/)
    pkg_list.push("@base")
    pkg_list.push("@core")
    pkg_list.push("@console-internet")
    if !service_name.match(/sl_6/)
      pkg_list.push("@network-file-system-client")
    end
    pkg_list.push("@system-admin-tools")
    if service_name.match(/centos_6|rhel_6|oel_6/)
      pkg_list.push("redhat-lsb-core")
    end
    pkg_list.push("grub")
    pkg_list.push("e2fsprogs")
    pkg_list.push("lvm2")
    pkg_list.push("kernel-devel")
    pkg_list.push("kernel-headers")
    pkg_list.push("libselinux-ruby")
    pkg_list.push("tk")
    pkg_list.push("lftp")
    pkg_list.push("dos2unix")
    pkg_list.push("unix2dos")
    pkg_list.push("avahi")
    pkg_list.push("ntp")
    pkg_list.push("rsync")
    if service_name.match(/sl_6/)
      pkg_list.push("-samba-client")
    end
  end
  return pkg_list
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
  tmp_file = "/tmp/postinstall"
  if service_name.match(/centos|rhel|sl_|oel/)
    message = "Appending:\tPost install script "+output_file
    command = "cp #{output_file} #{tmp_file}"
    file=File.open(tmp_file, 'a')
    output = "\n%post\n"
    command = "cat #{tmp_file} >> #{output_file} ; rm #{tmp_file}"
  else
    file=File.open(tmp_file, 'w')
    output = "#!/bin/sh\n"
    command = "cp #{tmp_file} #{output_file} ; rm #{tmp_file}"
  end
  file.write(output)
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  file.close
  message = "Creating:\tPost install script "+output_file
  execute_command(message,command)
  if $verbose_mode == 1
    puts "Information:\tInstall file "+output_file+" contents:"
    puts
    system("cat #{output_file}")
    puts
  end
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
