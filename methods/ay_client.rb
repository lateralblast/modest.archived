# Code for AutoYast clients

# Configure AutoYast client

def configure_ay_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  configure_ks_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)
  return
end

# Unconfigure AutoYast client

def unconfigure_ay_client(client_name,client_mac,service_name)
  unconfigure_ks_client(client_name,client_mac,service_name)
  return
end
