
# Solaris Zones support code

# List available zones

def list_zones()
  puts "Available Zones:"
  message = ""
  command = "zoneadm list |grep -v global"
  output  = execute_command(message,command)
  puts output
  return
end

# Create zone

def create_zone(client_name,zone_dir,output_file,client_rel)
  if $os_rel.match(/11/) and client_rel.match(/10/)
    branded_url = "http://www.oracle.com/technetwork/server-storage/solaris11/vmtemplates-zones-1949718.html"
    branded_dir = "/export/zones"
    if $os_arch.match(/i386/)
      branded_file = branded_dir+"solaris-10u11-x86.bin"
    else
      branded_file = branded_dir+"solaris-10u11-sparc.bin"
    end
    check_zfs_fs_exists(branded_dir)
    if !File.exists(branded_file)
      puts "Warning:\tBranded zone templates not found"
      puts "Information:\tDownload them from "+branded_url
      puts "Information:\tCopy them to "+branded_dir
    end
  end
  zone_nic = $q_struct["ipv4_interface_name"].value
  message = "Creating:\tSolaris "+client_rel+" Zone "+client_name=" in "+zone_dir
  command = "zonecfg -z #{client_name} -f #{output_file} \"create ; set zonepath=#{zone_dir} ; exit\""
  execute_command(message,command)
  message = "Setting:\tZone interface to "+zone_nic
  command = "zonecfg -z #{client_name} \"select anet linkname=#{zone_nic} ; end\""
  execute_command(message,command)
  message = "Installing:\tZone "+client_name
  command = "zoneadm -z #{client_name} install"
  execute_command(message,command)
  if $use_serial == 1
    system("zlogin #{client_name}")
  end
  return
end

# Delete zone

def unconfigure_zone(client_name)
  message = "Deleting:\tZone "+client_name
  command = "zonecfg -z #{client_name}"
  execute_command(message,command)
  return
end

# Boot zone

def boot_zone(client_name)
  message = "Booting:\tZone "+client_name
  command = "zoneadm -z #{client_name} boot"
  execute_command(message,command)
  return
end

# Shutdown zone

def stop_zone(client_name)
  message = "Stopping:\tZone "+client_name
  command = "zlogin #{client_name} \"shutdown -y -i 0\""
  execute_command(message,command)
  return
end

# Configure zone

def configure_zone(client_name,client_mac,client_arch,client_os,client_rel)
  if client_rel.match(/11/)
    populate_ai_client_profile_questions(client_ip,client_name)
    output_file = $work_dir+"/"+client_name+"_zone_profile.xml"
    process_questions()
    create_zone_profile_xml(output_file)
  else
    populate_js_client_profile_questions(client_ip,client_name)
    output_file = $work_dir+"/"+client_name+"_zone_profile.sysidcfg"
    process_questions()
    create_zone_profile_sysidcfg(output_file)
  end
  if !File.directory?($zone_base_dir)
    check_zfs_fs_exists($zone_base_dir)
    message = "Setting:\tMount point for "+$zone_base_dir
    command = "zfs set #{$default_zpool}#{$zone_base_dir} mountpoint=#{$zone_base_dir}"
    execute_command(message,command)
  end
  zone_dir = $zone_base_dir+"/"+client_name
  create_zone(client_name,zone_dir,output_file,client_rel)
  return
end
