
# Jumpstart client routines

# Create sysid file

def create_js_sysid_file(client_name,sysid_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tSysid file "+sysid_file+" for "+client_name
  end
  file=File.open(sysid_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+"="+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  return
end

# Create machine file

def create_js_machine_file(client_name,machine_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tMachine file "+machine_file+" for "+client_name
  end
  file=File.open(machine_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output = $q_struct[key].value+"\n"
      else
        output = $q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  return
end

# Get rules karch line

def create_js_rules_file(client_name,client_karch,rules_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tRules file "+rules_file+" for "+client_name
  end
  client_karch = %x[uname -m]
  client_karch = client_karch.chomp
  karch_line   = "karch "+client_karch+" - machine."+client_name+" -"
  file         = File.open(rules_file,"w")
  file.write("#{karch_line}\n")
  file.close
  return karch_line
end

# List jumpstart clients

def list_js_clients()
  puts "Jumpstart clients:"
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/sol/) and !service_name.match(/sol_11/)
      repo_version_dir = $repo_base_dir+"/"+service_name
      clients_dir      = repo_version_dir+"/clients"
      if File.directory?(clients_dir)
        client_list = Dir.entries(clients_dir)
        client_list.each do |client_name|
          if client_name.match(/[A-z]/)
            puts client_name+" service = "+service_name
          end
        end
      end
    end
  end
  return
end

# Check Jumpstart config

def check_js_config(client_name,client_dir,repo_version_dir,os_version)
  file_name     = "check"
  check_script  = repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  rules_ok_file = client_dir+"/rules.ok"
  if File.exists?(rules_ok_file)
    message = "Removing:\tExisting rules.ok file for client "+client_name
    command = "rm #{rules_ok_file}"
    output  = execute_command(message,command)
  end
  if !File.exists?("#{client_dir}/check")
    message = "Copying:\tCheck script "+check_script+" to "+client_dir
    command = "cd #{client_dir} ; cp -p #{check_script} ."
    output  = execute_command(message,command)
  end
  message    = "Checking:\tSum for rules file for "+client_name
  command    = "cd #{client_dir} ; sum rules |awk '{print $1}'"
  output     = execute_command(message,command)
  rules_sum  = output.chomp
  message    = "Copying:\tRules file"
  command    = "cd #{client_dir}; cp rules rules.ok"
  output     = execute_command(message,command)
  file       = File.open(rules_ok_file,"a")
  file.write("# version = 2 checksum=#{rules_sum}\n")
  file.close
  return
end

# Remove client

def remove_js_client(client_name,repo_version_dir,service_name)
  remove_dhcp_client(client_name)
  return
end

# Configure client PXE boot

def configure_js_pxe_client(client_name,client_mac,client_arch,service_name,repo_version_dir,publisher_host)
  if client_arch.match(/i386/)
    tftp_pxe_file = client_mac.gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    tftp_pxe_file = "01"+tftp_pxe_file+".bios"
    test_file     = $tftp_dir+"/"+tftp_pxe_file
    if !File.exists?(test_file)
      pxegrub_file = service_name+"/boot/grub/pxegrub"
      message      = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
      command      = "cd #{$tftp_dir} ; ln -s #{pxegrub_file} #{tftp_pxe_file}"
      execute_command(message,command)
    end
    pxe_cfg_file = client_mac.gsub(/:/,"")
    pxe_cfg_file = "01"+pxe_cfg_file.upcase
    pxe_cfg_file = "menu.lst."+pxe_cfg_file
    pxe_cfg_file = $tftp_dir+"/"+pxe_cfg_file
    sysid_dir    = repo_version_dir+"/clients/"+client_name
    install_url  = publisher_host+":"+repo_version_dir
    sysid_url    = publisher_host+":"+sysid_dir
    file         = File.open(pxe_cfg_file,"w")
    file.write("default 0\n")
    file.write("timeout 3\n")
    file.write("title Oracle Solaris\n")
    if $text_install == 1
      file.write("\tkernel$ #{service_name}/boot/multiboot kernel/$ISADIR/unix - install nowin -B keyboard-layout=US-English,install_media=#{install_url},install_config=#{sysid_url},sysid_config=#{sysid_url}\n")
    else
      file.write("\tkernel$ #{service_name}/boot/multiboot kernel/$ISADIR/unix - install -B keyboard-layout=US-English,install_media=#{install_url},install_config=#{sysid_url},sysid_config=#{sysid_url}\n")
    end
    file.write("\tmodule$ #{service_name}/boot/$ISADIR/x86.miniroot\n")
    file.close
    if $verbose_mode == 1
      puts "Created:\tPXE menu file "+pxe_cfg_file+":"
      system("cat #{pxe_cfg_file}")
    end
  end
  return
end

# Configure DHCP client

def configure_js_dhcp_client(client_name,client_mac,client_ip,service_name)
  add_dhcp_client(client_name,client_mac,client_ip,service_name)
  return
end

# Unconfigure DHCP client

def unconfigure_js_dhcp_client(client_name)
  remove_dhcp_client(client_name)
  return
end

# Unconfigure client

def unconfigure_js_client(client_name,client_mac,service_name)
  if service_name.match(/[A-z]/)
    repo_version_dir=$repo_base_dir+service_name
    if File.directory(repo_version_dir)
      remove_js_client(client_name,repo_version_dir,service_name)
    else
      puts "Warning:\tClient "+client_name+" does not exist under service "+service_name
    end
  end
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |temp_name|
    if temp_name.match(/sol/) and !temp_name.match(/sol_11/)
      repo_version_dir = $repo_base_dir+"/"+temp_name
      clients_dir      = repo_version_dir+"/clients"
      if File.directory?(clients_dir)
        client_list = Dir.entries(clients_dir)
        client_list.each do |dir_name|
          if dir_name.match(/#{client_name}/)
            remove_js_client(client_name,repo_version_dir,temp_name)
            return
          end
        end
      end
    end
  end
  return
end

# Configure client

def configure_js_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  if !service_name.match(/i386|sparc/)
    service_name = service_name+"_"+client_arch
  end
  if !service_name.match(/#{client_arch}/)
    puts "Service "+service_name+" and Client architecture "+client_arch+" do not match"
    return
  end
  repo_version_dir=$repo_base_dir+"/"+service_name
  if !File.directory?(repo_version_dir)
    puts "Warning:\tService "+service_name+" does not exist"
    puts
    list_js_services()
    return
  end
  if client_arch.match(/i386/)
    client_karch = client_arch
  else
    client_karch = $q_struct["client_karch"].value
  end
  # Create clients directory
  clients_dir = repo_version_dir+"/clients"
  check_dir_exists(clients_dir)
  # Create client directory
  client_dir = clients_dir+"/"+client_name
  check_dir_exists(client_dir)
  # Get release information
  repo_version_dir = $repo_base_dir+"/"+service_name
  os_version       = get_js_iso_version(repo_version_dir)
  os_update        = get_js_iso_update(repo_version_dir,os_version)
  # Populate sysid questions and process them
  populate_js_sysid_questions(client_name,client_ip,client_arch,client_model,os_version,os_update)
  process_questions()
  # Create sysid file
  sysid_file = client_dir+"/sysidcfg"
  create_js_sysid_file(client_name,sysid_file)
  # Populate machine questions
  populate_js_machine_questions(client_model,client_karch,publisher_host,service_name,os_version,os_update)
  process_questions()
  machine_file = client_dir+"/machine."+client_name
  create_js_machine_file(client_name,machine_file)
  # Create rules file
  rules_file = client_dir+"/rules"
  create_js_rules_file(client_name,client_karch,rules_file)
  configure_js_pxe_client(client_name,client_mac,client_arch,service_name,repo_version_dir,publisher_host)
  configure_js_dhcp_client(client_name,client_mac,client_ip,service_name)
  check_js_config(client_name,client_dir,repo_version_dir,os_version)
  return
end
