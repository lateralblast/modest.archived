# Solaris LDoms support code

# Question/config structure

Ld = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# List available LDoms

def list_ldoms()
  puts "Available LDoms:"
  message = ""
  command = "ldm list"
  output  = execute_command(message,command)
  puts output
  return
end

# Unconfigure LDom

def unconfigure_ldom(client_name)
  message = "Unbinding:\tDomain "+client_name
  command = "ldm unbind #{client_name}"
  execute_command(message,command)
  return
end

# Check LDoms installed

def check_ldom_install()
  ldm_bin = "/usr/sbin/ldm"
  if !File.exists?(ldm_bin)
    if $os_rel.match(/11/)
      message = "Installing:\tLDoms software"
      command = "pkg install ldomsmanager"
      execute_command(message,command)
    end
  end
  smf_service_name = "ldmd"
  enable_smf_service(smf_service_name)
  return
end

# Check LDom VCC

def check_ldom_vcc()
  message = "Checking:\tLDom VCC"
  command = "ldm list-services |grep 'primary-vcc'"
  output  = execute_command(message,command)
  if !output.match(/vcc/)
    message = "Enabling:\tVCC"
    command = "ldm add-vcc port-range=5000-5100 primary-vcc0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom VDS

def check_ldom_vds()
  message = "Checking:\tLDom VDS"
  command = "ldm list-services |grep 'primary-vds'"
  output  = execute_command(message,command)
  if !output.match(/vds/)
    message = "Enabling:\tVDS"
    command = "ldm add-vds primary-vds0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom vSwitch

def check_ldom_vsw()
  message = "Checking:\tLDom vSwitch"
  command = "ldm list-services |grep 'primary-vsw'"
  output  = execute_command(message,command)
  if !output.match(/vsw/)
    message = "Enabling:\tvSwitch"
    command = "ldm add-vsw net-dev=net0 primary-vsw0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom config

def check_ldom_config()
  message = "Checking:\tLDom configuration"
  command = "ldm list-config |grep 'current'"
  output  = execute_command(message,command)
  if output.match(/factory\-default/)
    message = "Checking:\tLDom configuration "+$ldom_config_name+" doesn't exist"
    command = "ldm list-config |grep #{$ldom_config_name}"
    output  = execute_command(message,command)
    if output.match(/#{$ldom_config_name}/)
      puts "Warning:\tLDom configuration "+$ldom_config_name+" already exists"
      exit
    end
    uname_a = %x[uname -a]
    if uname_a.match(/T5[1,2,4][2,4]|T3/)
      message = "Allocating:\t"+$ldom_primary_mau+"Crypto unit(s) to primary domain"
      command = "ldm set-mau #{$ldom_primary_mau} primary"
      execute_command(message,command)
    end
    message = "Allocating:\t"+$ldom_primary_vcpu+"vCPU unit(s) to primary domain"
    command = "ldm set-vcpu #{$ldom_primary_vcpu} primary"
    execute_command(message,command)
    message = "Starting:\tReconfiguration of primary domain"
    command = "ldm start-reconf primary"
    execute_command(message,command)
    message = "Allocating:\t"+$ldom_primary_mem+"to primary domain"
    command = "ldm set-memory #{$ldom_primary_mem} primary"
    execute_command(message,command)
    message = "Saving:\tLDom configuration of primary domain as "+$ldom_config_name
    command = "ldm add-config #{$ldom_config_name}"
    execute_command(message,command)
    command = "shutdown -y -g0 -i6"
    if $yes_to_all == 1
      message = "Warning:\tRebooting primary domain to enable settings"
      execute_command(message,command)
    else
      puts "Warning:\tReboot required for settings to take effect"
      puts "Infromation:\tExecute "+command
      exit
    end
  end
  return
end

# Configure LDom vntsd

def check_ldom_vntsd()
  smf_service_name = "vntsd"
  enable_smf_service(smf_service_name)
  return
end

# Configure LDom

def configure_ldom(client_name,client_mac,client_arch,client_os,client_rel)
  check_ldom_install()
  check_ldom_vcc()
  check_ldom_vds()
  check_ldom_vsw()
  check_ldom_config()
  check_ldom_vntsd()
  if !File.directory?($ldom_base_dir)
    check_zfs_fs_exists($ldom_base_dir)
    message = "Setting:\tMount point for "+$ldom_base_dir
    command = "zfs set #{$default_zpool}#{$ldom_base_dir} mountpoint=#{$ldom_base_dir}"
    execute_command(message,command)
  end
  return
end