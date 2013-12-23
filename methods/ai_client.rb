#!/usr/bin/env ruby

def delete_ai_client(client_name,service_name,client_mac)
  if !client_mac.match(/[A-z|0-9]/) or !service_name.match(/[A-z|0-9]/)
    repo_list=%x[installadm list -p |grep -v '^-' |grep -v '^Service']
    temp_client_name=""
    temp_client_mac=""
    temp_service_name=""
    repo_list.each do |line|
      line=line.chomp
      if line.match(/[A-z|0-9]/)
        if line.match(/^[A-z|0-9]/)
          line=line.gsub(/\s+/,"")
          temp_service_name=line
        else
          line=line.gsub(/\s+/,"")
          if line.match(/mac=/)
            (temp_client_name,temp_client_mac)=line.split(/mac=/)
            if temp_client_name.match(/^#{client_name}/)
              if !service_name.match(/[A-z|0-9]/)
                service_name=temp_service_name
              end
              if !client_mac.match(/[A-z|0-9]/)
                client_mac=temp_client_mac
              end
            end
          end
        end
      end
    end
  end
  if client_name.match(/[A-z]/) and service_name.match(/[A-z]/) and client_mac.match(/[A-z]/)
    message="Deleting:\tClient profile "+client_name+" from "+service_name
    command="installadm delete-profile -p #{client_name} -n #{service_name}"
    execute_command(message,command)
    message="Deleting:\tClient "+client_name+" with MAC address "+client_mac
    command="installadm delete-client "+client_mac
    execute_command(message,command)
  end
  return
end

# Get a list of valid shells

def get_valid_shells()
  vaild_shells=%x[ls /usr/bin |grep 'sh$' |awk '{print "/usr/bin/" $1 }']
  vaild_shells=vaild_shells.split("\n").join(",")
  return vaild_shells
end

# Make sure user ID is greater than 100

def check_valid_uid(answer)
  correct=1
  if answer.match(/[A-z]/)
    correct=0
  else
    if Integer(answer) < 100
      correct=0
      puts "UID must be greater than 100"
    end
  end
  return correct
end

# Make sure user group is greater than 10

def check_valid_gid(answer)
  correct=1
  if answer.match(/[A-z]/)
    correct=0
  else
    if Integer(answer) < 10
      correct=0
      puts "GID must be greater than 10"
    end
  end
  return correct
end

# Calculate route

def get_ipv4_default_route(client_ip)
  octets=client_ip.split(/\./)
  octets[3]="254"
  ipv4_default_route=octets.join(".")
  return ipv4_default_route
end

# Get the user home directory ZFS dataset name

def get_account_home_zfs_dataset(q_struct)
  account_home_zfs_dataset="/export/home/"+q_struct["account_login"].value
  return account_home_zfs_dataset
end

# Get the user home directory mount point

def get_account_home_mountpoint(q_struct)
  account_home_mountpoint="/export/home/"+q_struct["account_login"].value
  return account_home_mountpoint
end

# Code to check answers

def evaluate_answer(q_struct,key,answer)
  correct=1
  if q_struct[key].eval != "no"
    new_value=q_struct[key].eval
    if new_value.match(/^get/)
      new_value=eval"[#{new_value}]"
      answer=new_value
      q_struct[key].value=answer
    else
      correct=eval"[#{new_value}]"
      if correct == 1
        q_struct[key].value=answer
      end
    end
  end
  answer=answer.to_s
  if $verbose_mode == 1
    puts "Setting "+key+" to "+answer
  end
  return correct,q_struct
end

# Import AI manifest
# This is done to change the default manifest so that it doesn't point
# to the Oracle one amongst other things
# Check the structs for settings and more information

def import_ai_manifest(output_file,service_name)
  date=get_date_string()
  client_arch_list=[]
  service_base_name=get_service_base_name(service_name)
  if !service_name.match(/i386|sparc/) and !client_arch.match(/i386|sparc/)
    client_arch_list=["i386","SPARC"]
  else
    if service_name.match(/i386/)
      client_arch_list.push("i386")
    else
      if service_name.match(/sparc/)
        client_arch_list.push("SPARC")
      end
    end
  end
  client_arch_list.each do |sys_arch|
    lc_sys_arch=sys_arch.downcase
    backup_file=$work_dir+"/"+service_base_name+"_"+lc_sys_arch+"_orig_default.xml."+date
    message="Archiving:\tService configuration for "+service_base_name+"_"+lc_sys_arch+" to "+backup_file
    command="installadm export -n #{service_base_name}_#{lc_sys_arch} -m orig_default > #{backup_file}"
    output=execute_command(message,command)
    message="Validating:\tService configuration "+output_file
    command="AIM_MANIFEST=#{output_file} ; export AIM_MANIFEST ; aimanifest validate"
    output=execute_command(message,command)
    if output.match(/[A-z|0-9]/)
      puts "AI manifest file "+output_file+" does not contain a valid XML manifest"
      puts output
    else
      message="Importing:\t"+output_file+" to service "+service_name
      command="installadm update-manifest -n #{service_base_name}_#{lc_sys_arch} -m orig_default -f #{output_file}"
      output=execute_command(message,command)
    end
  end
  return
end

# Import a profile and associate it with a client

def import_ai_profile(output_file,client_name,client_mac,service_name)
  message="Creating:\tProfile for client "+client_name+" with MAC address "+client_mac
  command="installadm create-profile -n #{service_name} -f #{output_file} -p #{client_name} -c mac='#{client_mac}'"
  output=execute_command(message,command)
  return
end

# Code to change timeout and default menu entry in grub

def update_grub_cfg(client_mac)
  netboot_mac=client_mac.gsub(/:/,"")
  netboot_mac="00"+netboot_mac
  netboot_mac=netboot_mac.upcase
  grub_file="/etc/netboot/grub.cfg."+netboot_mac
  if File.exists?(grub_file)
    text=File.read(grub_file)
    text.each do |line|
      if line.match(/set timeout=30/)
        copy.push("set timeout=5")
        copy.push("set default=1")
      else
        copy.push(line)
      end
    end
    File.open(grub_file,"w") {|file| file.puts copy}
  end
end

# Main code to configure AI client services
# Called from main code

def configure_ai_client_services(client_arch,publisher_host,publisher_port,service_name)
  puts
  puts "You will be presented with a set of questions followed by the default output"
  puts "If you are happy with the default output simply hit enter"
  puts
  service_list=[]
  # Populate questions for AI manifest
  (q_struct,q_order)=populate_ai_manifest_questions(publisher_host,publisher_port)
  # Process questions
  q_struct=process_questions(q_struct,q_order)
  # Set name of AI manifest file to create and import
  if service_name.match(/i386|sparc/)
    service_list[0]=service_name
  end
  if !service_name.match(/[A-z|0-9]/)
    if client_arch.match(/i386|sparc/)
      service_name=get_service_name(client_arch)
      service_list[0]=service_name
    else
      ["i386","sparc"].each do |sys_arch|
        service_name=get_service_name(sys_arch)
        service_list.push(service_name)
      end
    end
  end
  service_list.each do |service_name|
    output_file=$work_dir+"/"+service_name+"_ai_manifest.xml"
    # Create manifest
    create_ai_manifest(q_struct,output_file)
    # Import AI manifest
    import_ai_manifest(output_file,service_name)
  end
  return
end

# Fix entry for client so it is given a fixed IP rather than one from the range

def fix_client_dhcpd_entry(client_name,client_mac,client_ip)
  copy=[]
  client_mac=client_mac.gsub(/:/,"")
  client_mac=client_mac.upcase
  file="/etc/inet/dhcpd4.conf"
  date_string=get_date_string()
  backup_file=$work_dir+"/dhcpd4.conf."+date_string
  message="Archiving:\tFile "+file+" to "+backup_file
  command="cp #{file} #{backup_file}"
  output=execute_command(message,command)
  text=File.read(file)
  text.each do |line|
    if line.match(/^host #{client_mac}/)
      copy.push("host #{client_name} {")
      copy.push("  fixed-address #{client_ip};")
    else
      copy.push(line)
    end
  end
  File.open(file,"w") {|file| file.puts copy}
  return
end

# Routine to actually add a client

def create_ai_client(client_name,client_arch,client_mac,service_name,client_ip)
  message="Creating:\tClient entry for #{client_name} with architecture #{client_arch} and MAC address #{client_mac}"
  command="installadm create-client -n #{service_name} -e #{client_mac}"
  output=execute_command(message,command)
  if client_arch.match(/i386/) or client_arch.mach(/i386/)
    fix_client_dhcpd_entry(client_name,client_mac,client_ip)
    update_grub_cfg(client_mac)
    smf_service="svc:/network/dhcp/server:ipv4"
    refresh_smf_service(smf_service)
  end
  return
end

# Main code to actually add a client

def configure_ai_client(client_name,client_arch,client_mac,client_ip)
  # Populate questions for AI profile
  (q_struct,q_order)=populate_ai_profile_questions(client_ip,client_name)
  q_struct=process_questions(q_struct,q_order)
  output_file=$work_dir+"/"+client_name+"_ai_profile.xml"
  create_ai_profile(q_struct,output_file)
  puts "Configuring client "+client_name+" with MAC address "+client_mac
  output_file=$work_dir+"/"+client_name+"_ai_profile.xml"
  service_name=get_service_name(client_arch)
  import_ai_profile(output_file,client_name,client_mac,service_name)
  create_ai_client(client_name,client_arch,client_mac,service_name,client_ip)
  return
end
