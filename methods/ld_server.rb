# Control Domain related code

# Check LDoms installed

def check_cdom_install()
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

def check_cdom_vcc()
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

def check_cdom_vds()
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

def check_cdom_vsw()
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

def check_cdom_config()
  message = "Checking:\tLDom configuration"
  command = "ldm list-config |grep 'current'"
  output  = execute_command(message,command)
  if output.match(/factory\-default/)
    config  = $q_struct["cdom_name"].value
    message = "Checking:\tLDom configuration "+config+" doesn't exist"
    command = "ldm list-config |grep #{config}"
    output  = execute_command(message,command)
    if output.match(/#{config}/)
      puts "Warning:\tLDom configuration "+config+" already exists"
      exit
    end
    if $os_info.match(/T5[0-9]|T3/)
      mau     = $q_struct["cdom_mau"].value
      message = "Allocating:\t"+mau+"Crypto unit(s) to primary domain"
      command = "ldm set-mau #{mau} primary"
      execute_command(message,command)
    end
    vcpu    = $q_struct["cdom_vcpu"].value
    message = "Allocating:\t"+vcpu+"vCPU unit(s) to primary domain"
    command = "ldm set-vcpu #{vcpu} primary"
    execute_command(message,command)
    message = "Starting:\tReconfiguration of primary domain"
    command = "ldm start-reconf primary"
    execute_command(message,command)
    memory  = $q_struct["cdom_memory"].value
    message = "Allocating:\t"+memory+"to primary domain"
    command = "ldm set-memory #{memory} primary"
    execute_command(message,command)
    message = "Saving:\tLDom configuration of primary domain as "+config
    command = "ldm add-config #{config}"
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

def check_cdom_vntsd()
  smf_service_name = "vntsd"
  enable_smf_service(smf_service_name)
  return
end

# Configure LDom Control (primary) domain

def configure_cdom(publisher_host)
  service_name = ""
  check_dhcpd_config(publisher_host)
  populate_cdom_questions()
  process_questions(service_name)
  check_cdom_install()
  check_cdom_vcc()
  check_cdom_vds()
  check_cdom_vsw()
  check_cdom_config()
  check_cdom_vntsd()
  return
end

