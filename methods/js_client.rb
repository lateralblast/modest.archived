
# Jumpstart client routines

# Create sysid file

def output_js_sysid(client_name,sysid_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tSysid file "+sysid_file+" for "+client_name
  end
  file=File.open(sysid_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output=$q_struct[key].value+"\n"
      else
        output=$q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  return
end

# Create machine file

def output_js_machine(client_name,machine_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tMachine file "+machine_file+" for "+client_name
  end
  file=File.open(machine_file,"w")
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if $q_struct[key].parameter == ""
        output=$q_struct[key].value+"\n"
      else
        output=$q_struct[key].parameter+" "+$q_struct[key].value+"\n"
      end
    end
    file.write(output)
  end
  return
end

# Get rules karch line

def output_js_rules(client_name,client_karch,rules_file)
  if $verbose_mode == 1
    puts
    puts "Creating:\tRules file "+rules_file+" for "+client_name
  end
  karch_line="karch "+client_karch+" - machine."+client_name+" -"
  file=File.open(rules_file,"w")
  file.write("#{karch_line}\n")
  file.close
  return karch_line
end

# List jumpstart clients

def list_js_clients()
  puts "Jumpstart clients:"
  service_list=Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/sol/) and !service_name.match(/sol_11/)
      repo_version_dir=$repo_base_dir+"/"+service_name
      clients_dir=repo_version_dir+"/clients"
      if File.directory?(clients_dir)
        client_list=Dir.entries(clients_dir)
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

def check_js_config(client_name,client_dir,repo_version_dir)
  file_name="check"
  check_script=repo_version_dir+"/Solaris_"+os_version+"/Misc/jumpstart_sample/"+file_name
  rules_ok_file=client_dir+"/rules.ok"
  if File.exists?(rules_ok_file)
    message="Removing:\tExisting rules.ok file for client "+client_name
    command="rm #{rules_ok_file}"
    output=execute_command(message,command)
  end
  message="Checking:\tConfiguration for "+client_name
  command="cd client_dir ; #{check_script} -r rules -p #{repo_version_dir}"
  output=execute_command(message,command)
  return
end

# Add client using add_install_client script

def add_js_client(client_name,client_ip,client_mac,client_dir,client_karch,repo_version_dir,os_version)
  file_name="add_install_client"
  add_script=repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  boot_dir=repo_version_dir+"/Solaris_"+os_version+"/Tools/Boot"
  message="Adding:\tInstall client "+client_name
  command="#{add_script} -i #{client_ip} -e #{client_mac} -s #{boot_dir} -p #{client_dir} -c #{client_dir} #{client_name} #{client_karch}"
  output=execute_command(message,command)
  return
end

# Remove client

def remove_js_client(client_name,repo_version_dir,service_name)
  os_version=get_js_iso_version(repo_version_dir)
  file_name="rm_install_client"
  rm_script=repo_version_dir+"/Solaris_"+os_version+"/Tools/"+file_name
  message="Removing:\tClient "+client_name+" from service "+service_name
  output=execute_command(message,command)
  return
end

# Unconfigure client

def unconfigure_js_client(client_name,service_name)
  if service_name.match(/[A-z]/)
    repo_version_dir=$repo_base_dir+service_name
    if File.directory(repo_version_dir)
      remove_js_client(client_name,repo_version_dir,service_name)
    else
      puts "Warning:\tClient "+client_name+" does not exist under service "+service_name
    end
  end
  service_list=Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/sol/) and !service_name.match(/sol_11/)
      repo_version_dir=$repo_base_dir+"/"+service_name
      clients_dir=repo_version_dir+"/clients"
      if File.directory?(clients_dir)
        client_list=Dir.entries(clients_dir)
        client_list.each do |dir_name|
          if dir_name.match(/#{client_name}/)
            remove_js_client(client_name,repo_version_dir,service_name)
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
    service_name=service_name+"_"+client_arch
  end
  if !service_name.match(/#{client_arch}/)
    puts "Service "+service_name+" and Client architecture "+client_arch+" do not match"
    return
  end
  repo_version_dir=$repo_base_dir+"/"+service_name
  if !File.directory?(repo_version_dir)
    puts "Service "+service_name+" does not exist"
    puts
    list_js_services()
    return
  end
  # Create clients directory
  clients_dir=repo_version_dir+"/clients"
  check_dir_exists(clients_dir)
  # Create client directory
  client_dir=clients_dir+"/"+client_name
  check_dir_exists(client_dir)
  # Get release information
  repo_version_dir=$repo_base_dir+"/"+service_name
  os_version=get_js_iso_version(repo_version_dir)
  os_update=get_js_iso_update(repo_version_dir,os_version)
  # Populate sysid questions and process them
  populate_js_sysid_questions(client_name,client_ip,client_arch,client_model,os_version,os_update)
  process_questions()
  # Create sysid file
  sysid_file=client_dir+"/sysidcfg"
  output_js_sysid(client_name,sysid_file)
  # Create rules file
  if client_arch.match(/i386/)
    client_karch=client_arch
  else
    client_karch=$q_struct["client_karch"].value
  end
  rules_file=client_dir+"/rules"
  output_js_rules(client_name,client_karch,rules_file)
  # Populate machine questions
  populate_js_machine_questions(client_model,client_karch,publisher_host,service_name,os_version,os_update)
  process_questions()
  machine_file=client_dir+"/machine."+client_name
  output_js_machine(client_name,machine_file)
  check_js_config(client_name,client_dir,repo_version_dir,os_version)
  add_js_client(client_name,client_ip,client_mac,client_dir,client_karch,repo_version_dir,os_version)
  return
end
