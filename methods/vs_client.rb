
# VSphere client routines

def get_vs_clients()
  client_list  = []
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/vmware/)
      repo_version_dir = $repo_base_dir+"/"+service_name
      file_list        = Dir.entries(repo_version_dir)
      file_list.each do |file_name|
        if file_name.match(/\.cfg$/) and !file_name.match(/boot\.cfg|isolinux\.cfg/)
          client_info = file_name+" service = "+service_name
          client_list.push(client_info)
        end
      end
    end
  end
  return client_list
end

# List ks clients

def list_vs_clients()
  puts
  puts "Available vSphere clients:"
  puts
  client_list = get_vs_clients()
  client_list.each do |client_info|
    puts client_info
  end
  puts
  return
end

# Configure client PXE boot

def configure_vs_pxe_client(client_name,client_mac,service_name)
  tftp_pxe_file  = client_mac.gsub(/:/,"")
  tftp_pxe_file  = tftp_pxe_file.upcase
  tftp_boot_file = "boot.cfg.01"+tftp_pxe_file
  tftp_pxe_file  = "01"+tftp_pxe_file+".pxelinux"
  test_file      = $tftp_dir+"/"+tftp_pxe_file
  if !File.exists?(test_file)
    pxelinux_file = service_name+"/usr/share/syslinux/pxelinux.0"
    message       = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
    command       = "cd #{$tftp_dir} ; ln -s #{pxelinux_file} #{tftp_pxe_file}"
    execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = client_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  ks_url       = "http://"+$default_host+"/"+service_name+"/"+client_name+".cfg"
  mboot_file   = "/"+service_name+"/mboot.c32"
  if $verbose_mode == 1
    puts "Creating:\tMenu config file "+pxe_cfg_file
  end
  file = File.open(pxe_cfg_file,"w")
  if $serial_mode == 1
    file.write("serial 0 115200\n")
  end
  file.write("DEFAULT ESX\n")
  file.write("LABEL ESX\n")
  file.write("KERNEL #{mboot_file}\n")
  if $text_mode == 1
    if $serial_mode == 1
      file.write("APPEND -c #{tftp_boot_file} text gdbPort=none logPort=none tty2Port=com1 ks=#{ks_url} +++\n")
    else
      file.write("APPEND -c #{tftp_boot_file} text ks=#{ks_url} +++\n")
    end
  else
    file.write("APPEND -c #{tftp_boot_file} ks=#{ks_url} +++\n")
  end
  file.write("IPAPPEND 1\n")
  file.close
  if $verbose_mode == 1
    puts "Created:\tPXE menu file "+pxe_cfg_file+":"
    system("cat #{pxe_cfg_file}")
  end
  tftp_boot_file=$tftp_dir+"/"+tftp_boot_file
  esx_boot_file=$tftp_dir+"/"+service_name+"/boot.cfg"
  if $verbose_mode == 1
    puts "Creating:\tBoot config file "+tftp_boot_file
  end
  copy=[]
  file=IO.readlines(esx_boot_file)
  file.each do |line|
    line=line.gsub(/\//,"")
    if $text_mode == 1
      if line.match(/^kernelopt/)
        if !line.match(/text/)
          line = line.chomp+" text\n"
        end
      end
    end
    if $serial_mode == 1
      if line.match(/^kernelopt/)
        if !line.match(/nofb/)
          line = line.chomp+" nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none\n"
        end
      end
    end
    if line.match(/^title/)
      copy.push(line)
      copy.push("prefix=#{service_name}\n")
    else
      copy.push(line)
    end
  end
  File.open(tftp_boot_file,"w") {|file_data| file_data.puts copy}
  if $verbose_mode == 1
    puts "Created:\tBoot config file "+tftp_boot_file+":"
    system("cat #{tftp_boot_file}")
  end
  return
end

# Unconfigure client PXE boot

def unconfigure_vs_pxe_client(client_name)
  client_mac = get_client_mac(client_name)
  if !client_mac
    puts "Warning:\tNo MAC Address entry found for "+client_name
    exit
  end
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxelinux"
  tftp_pxe_file = $tftp_dir+"/"+tftp_pxe_file
  if File.exists?(tftp_pxe_file)
    message = "Removing:\tPXE boot file "+tftp_pxe_file+" for "+client_name
    command = "rm #{tftp_pxe_file}"
    execute_command(message,command)
  end
  pxe_cfg_dir  = $tftp_dir+"/pxelinux.cfg"
  pxe_cfg_file = client_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  if File.exists?(pxe_cfg_file)
    message = "Removing:\tPXE boot config file "+pxe_cfg_file+" for "+client_name
    command = "rm #{pxe_cfg_file}"
    execute_command(message,command)
  end
  client_info  = get_vs_clients()
  service_name = client_info.grep(/#{client_name}/)[0].split(/ = /)[1].chomp
  ks_dir       = $tftp_dir+"/"+service_name
  ks_cfg_file  = ks_dir+"/"+client_name+".cfg"
  if File.exist?(ks_cfg_file)
    message = "Removing:\tKickstart boot config file "+ks_cfg_file+" for "+client_name
    command = "rm #{ks_cfg_file}"
    execute_command(message,command)
  end
  unconfigure_vs_dhcp_client(client_name)
  return
end

# Configure DHCP entry

def configure_vs_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  add_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  return
end

# Unconfigure DHCP client

def unconfigure_vs_dhcp_client(client_name)
  remove_dhcp_client(client_name)
  return
end

# Configure VSphere client

def configure_vs_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name,image_file)
  repo_version_dir=$repo_base_dir+"/"+service_name
  if !File.directory?(repo_version_dir)
    puts "Warning:\tService "+service_name+" does not exist"
    puts
    list_vs_services()
    exit
  end
  populate_vs_questions(service_name,client_name,client_ip)
  process_questions(service_name)
  output_file=repo_version_dir+"/"+client_name+".cfg"
  if File.exists?(output_file)
    File.delete(output_file)
  end
  output_file=repo_version_dir+"/"+client_name+".cfg"
  output_vs_header(output_file)
  # Output firstboot list
  post_list = populate_vs_firstboot_list(service_name)
  output_vs_post_list(post_list,output_file)
  # Output post list
  post_list = populate_vs_post_list(service_name)
  output_vs_post_list(post_list,output_file)
  if output_file
    FileUtils.chmod(0755,output_file)
  end
  configure_vs_pxe_client(client_name,client_mac,service_name)
  configure_vs_dhcp_client(client_name,client_mac,client_ip,client_arch,service_name)
  return
end

# Unconfigure VSphere client

def unconfigure_vs_client(client_name,client_mac,service_name)
  unconfigure_vs_pxe_client(client_name)
  unconfigure_vs_dhcp_client(client_name)
  return
end

# Populate firstboot commands

def populate_vs_firstboot_list(service_name)
  post_list   = []
  post_list.push("%firstboot --interpreter=busybox")
  post_list.push("")
  post_list.push("# enable HV (Hardware Virtualization to run nested 64bit Guests + Hyper-V VM)")
  post_list.push("grep -i 'vhv.allow' /etc/vmware/config || echo 'vhv.allow = \"TRUE\"' >> /etc/vmware/config")
  post_list.push("")
  post_list.push("# enable & start remote ESXi Shell  (SSH)")
  post_list.push("vim-cmd hostsvc/enable_ssh")
  post_list.push("vim-cmd hostsvc/start_ssh")
  post_list.push("")
  post_list.push("# enable & start ESXi Shell (TSM)")
  post_list.push("vim-cmd hostsvc/enable_esx_shell")
  post_list.push("vim-cmd hostsvc/start_esx_shell")
  post_list.push("")
  post_list.push("# supress ESXi Shell shell warning ")
  post_list.push("esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1")
  post_list.push("")
  post_list.push("# rename local datastore to something more meaningful")
  post_list.push("vim-cmd hostsvc/datastore/rename datastore1 \"$(hostname -s)-local-storage-1\"")
  post_list.push("")
  post_list.push("# enable management interface")
  post_list.push("cat > /tmp/enableVmkInterface.py << __ENABLE_MGMT_INT__")
  post_list.push("import sys,re,os,urllib,urllib2")
  post_list.push("")
  post_list.push("# connection info to MOB")
  post_list.push("")
  post_list.push("url = \"https://localhost/mob/?moid=ha-vnic-mgr&method=selectVnic\"")
  post_list.push("username = \"root\"")
  post_list.push("password = \"#{$default_root_password}\"")
  post_list.push("")
  post_list.push("# Create global variables")
  post_list.push("global passman,authhandler,opener,req,page,page_content,nonce,headers,cookie,params,e_params")
  post_list.push("")
  post_list.push("#auth")
  post_list.push("passman = urllib2.HTTPPasswordMgrWithDefaultRealm()")
  post_list.push("passman.add_password(None,url,username,password)")
  post_list.push("authhandler = urllib2.HTTPBasicAuthHandler(passman)")
  post_list.push("opener = urllib2.build_opener(authhandler)")
  post_list.push("urllib2.install_opener(opener)")
  post_list.push("")
  post_list.push("# Code to capture required page data and cookie required for post back to meet CSRF requirements  ###")
  post_list.push("req = urllib2.Request(url)")
  post_list.push("page = urllib2.urlopen(req)")
  post_list.push("page_content= page.read()")
  post_list.push("")
  post_list.push("# regex to get the vmware-session-nonce value from the hidden form entry")
  post_list.push("reg = re.compile('name=\"vmware-session-nonce\" type=\"hidden\" value=\"?([^\s^\"]+)\"')")
  post_list.push("nonce = reg.search(page_content).group(1)")
  post_list.push("")
  post_list.push("# get the page headers to capture the cookie")
  post_list.push("headers = page.info()")
  post_list.push("cookie = headers.get(\"Set-Cookie\")")
  post_list.push("")
  post_list.push("#execute method")
  post_list.push("params = {'vmware-session-nonce':nonce,'nicType':'management','device':'vmk0'}")
  post_list.push("e_params = urllib.urlencode(params)")
  post_list.push("req = urllib2.Request(url, e_params, headers={\"Cookie\":cookie})")
  post_list.push("page = urllib2.urlopen(req).read()")
  post_list.push("__ENABLE_MGMT_INT__")
  post_list.push("")
  post_list.push("python /tmp/enableVmkInterface.py")
  post_list.push("")
  post_list.push("# backup ESXi configuration to persist changes")
  post_list.push("/sbin/auto-backup.sh")
  post_list.push("")
  post_list.push("# enter maintenance mode")
  post_list.push("vim-cmd hostsvc/maintenance_mode_enter")
  post_list.push("")
  post_list.push("# copy %first boot script logs to persisted datastore")
  post_list.push("cp /var/log/hostd.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-hostd.log\"")
  post_list.push("cp /var/log/esxi_install.log \"/vmfs/volumes/$(hostname -s)-local-storage-1/firstboot-esxi_install.log\"")
  post_list.push("")
  if $serial_mode == 1
    post_list.push("# Fix bootloader to run in serial mode")
    post_list.push("sed -i '/no-auto-partition/ s/$/ text nofb com1_baud=115200 com1_Port=0x3f8 tty2Port=com1 gdbPort=none logPort=none/' /bootbank/boot.cfg")
    post_list.push("")
  end
  post_list.push("reboot")
  return post_list
end

# Populate post commands

def populate_vs_post_list(service_name)
  post_list   = []
  post_list.push("")
  return post_list
end

# Output the VSphere file header

def output_vs_header(output_file)
  if $verbose_mode == 1
    puts "Creating:\tVSphere file "+output_file
  end
  file=File.open(output_file, 'w')
  $q_order.each do |key|
    if $q_struct[key].type == "output"
      if !$q_struct[key].parameter.match(/[A-z]/)
        output=$q_struct[key].value+"\n"
      else
        output=$q_struct[key].parameter+" "+$q_struct[key].value+"\n"
        puts output
      end
      file.write(output)
    end
  end
  file.close
  return
end

# Output the ks packages list

def output_vs_post_list(post_list,output_file)
  file=File.open(output_file, 'a')
  post_list.each do |line|
    output=line+"\n"
    file.write(output)
  end
  file.close
  return
end

# Check service service_name

def check_vs_service_name(service_name)
  if !service_name.match(/[A-z]/)
    puts "Warning:\tService name not given"
    exit
  end
  client_list=Dir.entries($repo_base_dir)
  if !client_list.grep(service_name)
    puts "Warning:\tService name "+service_name+" does not exist"
    exit
  end
  return
end
