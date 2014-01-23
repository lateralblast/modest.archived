# Code to manage Linux containers

# Check LXC install

def check_lxc_install()
  message = "Checking:\tLXC Packages are installed"
  if $os_info.match(/Ubuntu/)
    command = "dpkg -l lxc"
    output  = execute_command(message,command)
    if output.match(/no packages/)
      message = "Installing:\tLXC Packages"
      command = "apt-get -y install lxc cloud-utils"
      execute_command(message,command)
    end
  else
    command = "rpm -ql libvirt"
    output  = execute_command(message,command)
    if output.match(/not installed/)
      message = "Installing:\tLXC Packages"
      command = "yum -y install libvirt libvirt-client python-virtinst"
      execute_command(message,command)
    end
  end
  return
end

# Configure a container

def contfigure_lxc(client_name,client_ip,client_mac,client_arch,client_os,client_rel,publisher_host)
  return
end
