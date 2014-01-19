
# AutoYast routines

# List available Ubuntu ISOs

def list_ps_isos()
  search_string = "ubuntu"
  list_linux_isos(search_string)
  return
end

# Configure Preseed server

def configure_ps_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
  search_string = "ubuntu"
  configure_linux_server(client_arch,publisher_host,publisher_port,service_name,iso_file,search_string)
  return
end

# List Preseed services

def list_ps_services()
  puts "Kickstart services:"
  service_list = Dir.entries($repo_base_dir)
  service_list.each do |service_name|
    if service_name.match(/sles/)
      puts service_name
    end
  end
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(service_name)
  unconfigure_ks_repo(service_name)
end
