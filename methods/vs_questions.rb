
# Questions for ks

# Construct ks network line

def get_vs_network()
  if $q_struct["bootproto"].value == "dhcp"
    result = "--device "+$q_struct["nic"].value+" --bootproto "+$q_struct["bootproto"].value
  else
    client_ip = $q_struct["ip"].value
    client_name = $q_struct["hostname"].value
    gateway = get_ipv4_default_route(client_ip)
    result = "--device="+$q_struct["nic"].value+" --bootproto="+$q_struct["bootproto"].value+" --ip="+client_ip+" --netmask="+$default_netmask+" --gateway="+gateway+" --nameserver="+$default_nameserver+" --hostname="+client_name+" --addvmportgroup=0"
  end
  return result
end

# Set network

def set_vs_network()
  if $q_struct["bootproto"].value == "dhcp"
    $q_struct["ip"].ask = "no"
    $q_struct["ip"].type = ""
    $q_struct["hostname"].ask = "no"
    $q_struct["hostname"].type = ""
  end
  return
end

# Construct ks password line

def get_vs_password()
  result = "--iscrypted "+$q_struct["root_crypt"].value.to_s
  return result
end

# Get install url

def get_vs_install_url(service_name)
  install_url = "http://"+$default_host+"/"+service_name
  return install_url
end

# Get kickstart header

def get_vs_header(client_name)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+client_name+" "+version
  return header
end

# Populate ks questions

def populate_vs_questions(service_name,client_name,client_ip)
  $q_struct = {}
  $q_order  = []

  name = "ks_header"
  config = Vs.new(
    type      = "output",
    question  = "VSphere file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_vs_header(client_name),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "vmaccepteula"
  config = Vs.new(
    type      = "output",
    question  = "Accept EULA",
    ask       = "yes",
    parameter = "",
    value     = "vmaccepteula",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install"
  config = Vs.new(
    type      = "output",
    question  = "Install type",
    ask       = "yes",
    parameter = "install",
    value     = "--firstdisk --overwritevmfs",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "nic"
  config = Vs.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "vmnic0",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootproto"
  config = Vs.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "set_vs_network()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "hostname"
  config = Vs.new(
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

  name = "ip"
  config = Vs.new(
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

  name = "network"
  config = Vs.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_vs_network()",
    valid     = "",
    eval      = "get_vs_network()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_password"
  config = Vs.new(
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
  config = Vs.new(
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
  config = Vs.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_vs_password()",
    valid     = "",
    eval      = "get_vs_password()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "finish"
  config = Vs.new(
    type      = "output",
    question  = "Finish Command",
    ask       = "yes",
    parameter = "",
    value     = "reboot",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return
end

