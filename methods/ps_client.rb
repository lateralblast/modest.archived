# Code for Preseed clients

# Configure Preseed client

def configure_ps_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  configure_ks_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  return
end

# Unconfigure Preseed client

def unconfigure_ps_client(client_name,client_mac,service_name)
  unconfigure_ks_client(client_name,client_mac,service_name)
  return
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

# Populate post commands

def populate_ps_post_list()
  post_list        = []
  client_ip        = $q_struct["ip"].value
  client_gateway   = $q_struct["gateway"].value
  client_netmask   = $q_struct["netmask"].value
  client_network   = $q_struct["network_address"].value
  client_broadcast = $q_struct["broadcast"].value
  admin_user       = $q_struct["admin_username"].value
  post_list.push("# Install additional pacakges")
  post_list.push("")
  post_list.push("export TERM=vt100")
  post_list.push("export LANGUAGE=en_US.UTF-8")
  post_list.push("export LANG=en_US.UTF-8")
  post_list.push("export LC_ALL=en_US.UTF-8")
  post_list.push("locale-gen en_US.UTF-8")
  post_list.push("dpkg-reconfigure locales")
  post_list.push("")
  post_list.push("# Configure apt mirror")
  post_list.push("")
  post_list.push("cp /etc/apt/sources.list /etc/apt/sources.list.orig")
  post_list.push("sed -i 's,#{$default_ubuntu_mirror},#{local_ubuntu_mirror},g' /etc/apt/sources.list.orig")
  post_list.push("")
  post_list.push("apt-get install -y avahi-daemon")
  post_list.push("apt-get install -y libterm-readkey-perl 2> /dev/null")
  post_list.push("apt-get install -y puppet 2> /dev/null")
  post_list.push("apt-get install -y nfs-common 2> /dev/null")
  post_list.push("apt-get install -y openssh-server 2> /dev/null")
  post_list.push("apt-get install -y python-software-properties 2> /dev/null")
  post_list.push("apt-get install -y software-properties-common 2> /dev/null")
  post_list.push("")
  post_list.push("# Install VM tools")
  post_list.push("")
  post_list.push("if [ \"`dmidecode |grep VMware`\" ]; then")
  post_list.push("  apt-get install -y open-vm-tools")
  post_list.push("fi")
  post_list.push("")
  post_list.push("# Setup sudoers")
  post_list.push("")
  post_list.push("echo \"#{admin_user} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/sysadmin")
  post_list.push("")
  post_list.push("# Enable serial console")
  post_list.push("")
  post_list.push("echo 'start on stopped rc or RUNLEVEL=[12345]' > /etc/init/ttyS0.conf")
  post_list.push("echo 'stop on runlevel [!12345]' >> /etc/init/ttyS0.conf")
  post_list.push("echo 'respawn' >> /etc/init/ttyS0.conf")
  post_list.push("echo 'exec /sbin/getty -L 115200 ttyS0 vt100' >> /etc/init/ttyS0.conf")
  post_list.push("start getty")
  post_list.push("")
  post_list.push("# Configure network")
  post_list.push("")
  net_config = "/etc/network/interfaces"
  post_list.push("sed -i 's/^#GRUB_TERMINAL/GRUB_TERMINAL=console/' /etc/default/grub")
  post_list.push("echo 'GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"' >> /etc/default/grub")
  post_list.push("echo '# The loopback network interface' > #{net_config}")
  post_list.push("echo 'auto lo' >> #{net_config}")
  post_list.push("echo 'iface lo inet loopback' >> #{net_config}")
  post_list.push("echo '# The primary network interface' >> #{net_config}")
  post_list.push("echo 'iface eth0 inet static' >> #{net_config}")
  post_list.push("echo 'address #{client_ip}' >> #{net_config}")
  post_list.push("echo 'gateway #{client_gateway}' >> #{net_config}")
  post_list.push("echo 'netmask #{client_netmask}' >> #{net_config}")
  post_list.push("echo 'network #{client_network}' >> #{net_config}")
  post_list.push("echo 'broadcast #{client_broadcast}' >> #{net_config}")
  post_list.push("")
  return post_list
end
