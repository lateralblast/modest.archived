# Code for *BSD PXE clients

# List BSD clients

def list_xb_clients()

  return
end

# Configure client PXE boot

def configure_xb_pxe_client(client_name,client_ip,client_mac,client_arch,service_name)
  tftp_pxe_file = client_mac.gsub(/:/,"")
  tftp_pxe_file = tftp_pxe_file.upcase
  tftp_pxe_file = "01"+tftp_pxe_file+".pxeboot"
  test_file     = $tftp_dir+"/"+tftp_pxe_file
  tmp_file      = "/tmp/pxecfg"
  if File.symlink?(test_file)
    message = "Removing:\tOld PXE boot file "+test_file
    command = "rm #{test_file}"
    execute_command(message,command)
  end
  message = "Creating:\tPXE boot file for "+client_name+" with MAC address "+client_mac
  command = "cd #{$tftp_dir} ; ln -s #{pxeboot_file} #{tftp_pxe_file}"
  execute_command(message,command)
  pxe_cfg_dir  = $tftp_dir+"/pxeboot.cfg"
  pxe_cfg_file = client_mac.gsub(/:/,"-")
  pxe_cfg_file = "01-"+pxe_cfg_file
  pxe_cfg_file = pxe_cfg_file.downcase
  pxe_cfg_file = pxe_cfg_dir+"/"+pxe_cfg_file
  return
end
