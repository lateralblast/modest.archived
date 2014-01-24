# Code to manage Linux containers

# Structure for questions

Lx = Struct.new(:question, :ask, :value, :valid, :eval)

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
  check_dir_exists($lxc_base_dir)
  return
end

