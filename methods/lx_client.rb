# Code for LXC clients

# List availabel clients

def list_lxcs()
  puts
  puts "Available LXC clients:"
  puts
  client_list = %x[lxc-ls]
  client_list = client_list.xplit(/\n/)
  client_list.each do |client_name|
    client_name = client_name.chomp
    puts client_name
  end
  return
end

# Start container

def boot_lxc(client_name)
  message = "Checking:\tStatus of "+client_name
  command = "lxc-list |grep '^#{client_name}'"
  output  = execute_command(message,command)
  if !output.match(/RUNNING/)
    message = "Starting:\tClient "+client_name
    command = "lxc-start -n #{client_name} -d"
    execute_command(message,command)
    if $serial_mode == 1
      system("lxc-console -n #{client_name}")
    end
  end
  return
end

# Stop container

def stop_lxc(client_name)
  message = "Checking:\tStatus of "+client_name
  command = "lxc-list |grep '^#{client_name}'"
  output  = execute_command(message,command)
  if output.match(/RUNNING/)
    message = "Stopping:\tClient "+client_name
    command = "lxc-stop -n #{client_name}"
    execute_command(message,command)
  end
  return
end

# Create Centos container configuration

def create_centos_lxc_config(client_name)
  tmp_file = "/tmp/lxc_"+client_name
  file = File.open(tmp_file,"w")
  file.write("\n")
  file.close
  return
end

# Create Ubuntu container config

def create_ubuntu_lxc_config(client_name,client_ip,client_mac)
  tmp_file = "/tmp/lxc_"+client_name
  client_dir  = $lxc_base_dir+"/"+client_name
  config_file = client_dir+"/config"
  message = "Creating:\tConfiguration for "+client_name
  command = "cp #{config_file} #{tmp_file}"
  execute_command(message,command)
  copy = []
  info = IO.readlines(config_file)
  info.each do |line|
    if line.match(/hwaddr/)
      if client_mac.match(/[0-9]/)
        output = "lxc.network.hwaddr = "+client_mac+"\n"
        copy.push(output)
        output = "lxc.network.ipv4 = "+client_ip+"\n"
        copy.push(output)
      else
        copy.push(line)
        output = "lxc.network.ipv4 = "+client_ip+"\n"
        copy.push(output)
      end
    else
      copy.push(line)
    end
  end
  copy = copy.join
  File.open(tmp_file,"w") { |file| file.write(copy) }
  message = "Creating:\tNetwork configuration file "+config_file
  command = "cp #{tmp_file} #{config_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file(config_file)
  file = File.open(tmp_file,"w")
  gateway    = $q_struct["gateway"].value
  broadcast  = $q_struct["broadcast"].value
  netmask    = $q_struct["netmask"].value
  network    = $q_struct["network_address"].value
  nameserver = $q_struct["nameserver"].value
  file.write("# The loopback network interface\n")
  file.write("auto lo\n")
  file.write("iface lo inet loopback\n")
  file.write("\n")
  file.write("auto eth0\n")
  file.write("iface eth0 inet static\n")
  file.write("address #{client_ip}\n")
  file.write("netmask #{netmask}\n")
  file.write("gateway #{gateway}\n")
  file.write("network #{network}\n")
  file.write("broadcast #{broadcast}\n")
  file.write("dns-nameservers #{nameserver}\n")
  file.write("post-up route add default gw 192.168.1.254\n")
  file.write("\n")
  file.close
  client_dir = client_dir+"/rootfs"
  net_file   = client_dir+"/etc/network/interfaces"
  message    = "Creating:\tNetwork interface file "+net_file
  command    = "cp #{tmp_file} #{net_file} ; rm #{tmp_file}"
  execute_command(message,command)
  user_username = $q_struct["user_username"].value
  user_uid      = $q_struct["user_uid"].value
  user_gid      = $q_struct["user_gid"].value
  user_crypt    = $q_struct["user_crypt"].value
  root_crypt    = $q_struct["root_crypt"].value
  user_fullname = $q_struct["user_fullname"].value
  user_home     = $q_struct["user_home"].value
  user_shell    = $q_struct["user_shell"].value
  passwd_file   = client_dir+"/etc/passwd"
  shadow_file   = client_dir+"/etc/shadow"
  info          = IO.readlines(passwd_file)
  file          = File.open(tmp_file,"w")
  info.each do |line|
    field = line.split(":")
    if field[0] != "ubuntu" and field[0] != "#{user_username}"
      file.write(line)
    end
  end
  output = user_username+":x:"+user_uid+":"+user_gid+":"+user_fullname+":"+user_home+":"+user_shell+"\n"
  file.write(output)
  file.close
  message = "Creating:\tPassword file"
  command = "cat #{tmp_file} > #{passwd_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file(passwd_file)
  info = IO.readlines(shadow_file)
  file = File.open(tmp_file,"w")
  info.each do |line|
    field = line.split(":")
    if field[0] != "ubuntu" and field[0] != "root" and field[0] != "#{user_username}"
      file.write(line)
    end
    if field[0] == "root"
      field[1] = root_crypt
      copy = field.join(":")
      file.write(copy)
    end
  end
  output = user_username+":"+user_crypt+":::99999:7:::\n"
  file.write(output)
  file.close
  message = "Creating:\tShadow file"
  command = "cat #{tmp_file} > #{shadow_file} ; rm #{tmp_file}"
  execute_command(message,command)
  print_contents_of_file(shadow_file)
  client_home = client_dir+user_home
  message = "Creating:\tSSH directory for "+user_username
  command = "mkdir -p #{client_home}/.ssh ; cd #{client_dir}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(message,command)
  # Copy admin user keys
  rsa_file = user_home+"/.ssh/id_rsa.pub"
  dsa_file = user_home+"/.ssh/id_dsa.pub"
  key_file = client_home+"/.ssh/authorized_keys"
  if File.exists?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file,dsa_file].each do |pub_file|
    if File.exists?(pub_file)
      message = "Copying:\tSSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(message,command)
    end
  end
  message = "Creating:\tSSH directory for root"
  command = "mkdir -p #{client_dir}/root/.ssh ; cd #{client_dir} ; chown -R 0:0 root"
  execute_command(message,command)
  # Copy root keys
  rsa_file = "/root/.ssh/id_rsa.pub"
  dsa_file = "/root/.ssh/id_dsa.pub"
  key_file = client_dir+"/root/.ssh/authorized_keys"
  if File.exists?(key_file)
    system("rm #{key_file}")
  end
  [rsa_file,dsa_file].each do |pub_file|
    if File.exists?(pub_file)
      message = "Copying:\tSSH public key "+pub_file+" to "+key_file
      command = "cat #{pub_file} >> #{key_file}"
      execute_command(message,command)
    end
  end
  # Fix permissions
  message = "Fixing:\t\tSSH permissions for "+user_username
  command = "cd #{client_dir}/home ; chown -R #{user_uid}:#{user_gid} #{user_username}"
  execute_command(message,command)
  message = "Fixing:\t\tSSH permissions for root "
  command = "cd #{client_dir} ; chown -R 0:0 root"
  execute_command(message,command)
  # Add sudoers entry
  sudoers_file = client_dir+"/etc/sudoers.d/"+user_username
  message = "Creating:\tSudoers file "+sudoers_file
  command = "echo 'sysadmin ALL=(ALL) NOPASSWD:ALL' > #{sudoers_file}"
  execute_command(message,command)
  # Add default route
  rc_file = client_dir+"/etc/rc.local"
  info = IO.readlines(rc_file)
  file = File.open(tmp_file,"w")
  info.each do |line|
    if line.match(/exit 0/)
      output = "route add default gw #{gateway}\n"
      file.write(output)
      file.write(line)
    else
      file.write(line)
    end
  end
  file.close
  message = "Adding:\t\tDefault route to "+rc_file
  command = "cp #{tmp_file} #{rc_file} ; rm #{tmp_file}"
  execute_command(message,command)
  return
end

# Create standard LXC

def create_standard_lxc(client_name)
  message = "Creating:\tStandard container "+client_name
  if $os_info.match(/Ubuntu/)
    command = "lxc-create -t ubuntu -n #{client_name}"
  end
  execute_command(message,command)
  return
end

# Unconfigure LXC client

def unconfigure_lxc(client_name)
  stop_lxc(client_name)
  message = "Deleting:\tClient "+client_name
  command = "lxc-destroy -n #{client_name}"
  execute_command(message,command)
  client_ip = get_client_ip(client_name)
  remove_hosts_entry(client_name,client_ip)
  return
end

# Check LXC exists

def check_lxc_exists(client_name)
  message = "Checking:\tLXC "+client_name+" exists"
  command = "lxc-ls |grep '#{client_name}'"
  output  = execute_command(message,command)
  if !output.match(/#{client_name}/)
    puts "Warning:\tClient "+client_name+" doesn't exist"
    exit
  end
  return
end

# Check LXC doesn't exist

def check_lxc_doesnt_exist(client_name)
  message = "Checking:\tLXC "+client_name+" doesn't exist"
  command = "lxc-ls |grep '#{client_name}'"
  output  = execute_command(message,command)
  if output.match(/#{client_name}/)
    puts "Warning:\tClient "+client_name+" already exists"
    exit
  end
  return
end

# Populate post install list

def populate_lxc_post()
  post_list = []
  post_list.push("#!/bin/sh")
  post_list.push("# Install additional pacakges")
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("locale-gen en_US.UTF-8")
  post_list.push("")
  post_list.push("if [ \"`lsb_release -i |awk '{print $3}'`\" = \"Ubuntu\" ] ; then")
  post_list.push("  dpkg-reconfigure locales")
  post_list.push("  cp /etc/apt/sources.list /etc/apt/sources.list.orig")
  post_list.push("  sed -i 's,#{$default_ubuntu_mirror},#{$local_ubuntu_mirror},g' /etc/apt/sources.list.orig")
  post_list.push("  apt-get install -y avahi-daemon")
  post_list.push("  apt-get install -y libterm-readkey-perl 2> /dev/null")
  post_list.push("  apt-get install -y puppet 2> /dev/null")
  post_list.push("  apt-get install -y nfs-common 2> /dev/null")
  post_list.push("  apt-get install -y openssh-server 2> /dev/null")
  post_list.push("  apt-get install -y python-software-properties 2> /dev/null")
  post_list.push("  apt-get install -y software-properties-common 2> /dev/null")
  post_list.push("fi")
  post_list.push("")
  repo_file = "/etc/yum.repos.d/CentOS-Base.repo"
  post_list.push("if [ \"`lsb_release -i |awk '{print $3}'`\" = \"Centos\" ] ; then")
  post_list.push("  sed -i 's/^mirror./#&/g' #{repo_file}")
  post_list.push("  sed -i 's/^#\\(baseurl\\)/\\1/g' #{repo_file}")
  post_list.push("  sed -i 's,#{$default_centos_mirror},#{$local_centos_mirror}' #{repo_file}")
  post_list.push("  yum -y install avahi-daemon")
  post_list.push("  chkconfig avahi-daemon on")
  post_list.push("  service avahi-daemon start")
  post_list.push("  rpm -i http://fedora.mirror.uber.com.au/epel/5/i386/epel-release-5-4.noarch.rpm")
  post_list.push("  yum -y install puppet")
  post_list.push("fi")
  post_list.push("")
  return post_list
end

# Create post install package on container

def create_lxc_post(client_name,post_list)
  tmp_file   = "/tmp/post"
  client_dir = $lxc_base_dir+"/"+client_name
  post_file  = client_dir+"/rootfs/root/post_install.sh"
  file       = File.open(tmp_file,"w")
  post_list.each do |line|
    output = line+"\n"
    file.write(output)
  end
  file.close
  message = "Creating:\tPost install script"
  command = "cp #{tmp_file} #{post_file} ; chmod +x #{post_file} ; rm #{tmp_file}"
  execute_command(message,command)
  return
end

# Execute post install script

def execute_lxc_post(client_name)
  client_dir = $lxc_base_dir+"/"+client_name
  post_file  = client_dir+"/root/post_install.sh"
  if !File.exists?(post_file)
    post_list = populate_lxc_post()
    create_lxc_post(client_name,post_list)
  end
  boot_lxc(client_name)
  post_file = "/root/post_install.sh"
  message   = "Executing:\tPost install script on "+client_name
  command   = "ssh -o 'StrictHostKeyChecking no' #{client_name} '#{post_file}'"
  execute_command(message,command)
  return
end

# Configure a container

def configure_lxc(client_name,client_ip,client_mac,client_arch,client_os,client_rel,publisher_host,image_file,service_name)
  check_lxc_doesnt_exist(client_name)
  if !service_name.match(/[A-z]/) and !image_file.match(/[A-z]/)
    puts "Warning:\tImage file or Service name not specified"
    puts "Warning:\tIf this is the first time you have run this command it may take a while"
    puts "Information:\tCreating standard container"
    populate_lxc_client_questions(client_ip)
    process_questions(service_name)
    create_standard_lxc(client_name)
    if $os_info.match(/Ubuntu/)
      create_ubuntu_lxc_config(client_name,client_ip,client_mac)
    end
    if $os_info.match(/RedHat|Centos/)
      create_centos_lxc_config(client_name,client_ip,client_mac)
    end
  else
    if service_name.match(/[A-z]/)
      image_file = $lxc_image_dir+"/"+service_name.gsub(/([0-9])_([0-9])/,'\1.\2').gsub(/_/,"-").gsub(/x86.64/,"x86_64")+".tar.gz"
    end
    if image_file.match(/[A-z]/)
      if !File.exists?(image_file)
        puts "Warning:\tImage file "+image_file+" does not exist"
        exit
      end
    end
  end
  add_hosts_entry(client_name,client_ip)
  boot_lxc(client_name)
  post_list = populate_lxc_post()
  create_lxc_post(client_name,post_list)
  return
end
