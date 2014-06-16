# Questions for *BSD and other (e.g. CoreOS)

# Populate CoreOS questions

def populate_coreos_questions(service_name,client_name,client_ip)
  $q_struct = {}
  $q_order  = []

  name = "hostname"
  config = Ks.new(
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = client_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "nic"
  config = Ks.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = $default_x86_vm_net,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ip"
  config = Ks.new(
    type      = "",
    question  = "IP",
    ask       = "yes",
    parameter = "",
    value     = client_ip,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "netmask"
  config = Ks.new(
    type      = "",
    question  = "Netmask",
    ask       = "yes",
    parameter = "",
    value     = $default_netmask,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "nameserver"
  config = Ks.new(
    type      = "",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "",
    value     = $default_nameserver,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  gateway = client_ip.split(/\./)[0..2].join(".")+".254"

  name = "gateway"
  config = Ks.new(
    type      = "",
    question  = "Gateway",
    ask       = "yes",
    parameter = "",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  broadcast = client_ip.split(/\./)[0..2].join(".")+".255"

  name = "broadcast"
  config = Ks.new(
    type      = "",
    question  = "Broadcast",
    ask       = "yes",
    parameter = "",
    value     = broadcast,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  network_address = client_ip.split(/\./)[0..2].join(".")+".0"

  name = "network_address"
  config = Ks.new(
    type      = "",
    question  = "Network Address",
    ask       = "yes",
    parameter = "",
    value     = network_address,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_password"
  config = Ks.new(
    type      = "",
    question  = "Root Password",
    ask       = "yes",
    parameter = "",
    value     = $default_root_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_crypt"
  config = Ks.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootpw"
  config = Ks.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_ks_root_password()",
    valid     = "",
    eval      = "get_ks_root_password()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_user"
  config = Ks.new(
    type      = "",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_user,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_uid"
  config = Ks.new(
    type      = "",
    question  = "Admin User ID",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_uid,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_shell"
  config = Ks.new(
    type      = "",
    question  = "Admin User Shell",
    parameter = "",
    value     = $default_admin_shell,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_home"
  config = Ks.new(
    type      = "",
    question  = "Admin User Home Directory",
    ask       = "yes",
    parameter = "",
    value     = "/home/"+$default_admin_user,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_group"
  config = Ks.new(
    type      = "",
    question  = "Admin User Group",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_group,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_gid"
  config = Ks.new(
    type      = "",
    question  = "Admin Group ID",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_gid,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_password"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password",
    ask       = "yes",
    parameter = "",
    value     = $default_admin_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_crypt"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_admin_password_crypt()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

end

def create_coreos_client_config()
end
