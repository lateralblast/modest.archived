# Code for AutoYast clients

# List AutoYest clients

def list_ay_clients()
  service_type = "AutoYast"
  list_clients(service_type)
  return
end

# Configure AutoYast client

def configure_ay_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name,image_file)
  configure_ks_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name,image_file)
  return
end

# Unconfigure AutoYast client

def unconfigure_ay_client(client_name,client_mac,service_name)
  unconfigure_ks_client(client_name,client_mac,service_name)
  return
end
