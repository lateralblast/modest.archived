
# Questions for ks

# Construct ks language line

def get_ks_language()
  result = "--default="+$q_struct["install_language"].value+" "+$q_struct["install_language"].value
  return result
end

# Construct ks xconfig line

def get_ks_xconfig()
  result = "--card "+$q_struct["videocard"].value+" --videoram "+$q_struct["videoram"].value+" --hsync "+$q_struct["hsync"].value+" --vsync "+$q_struct["vsync"].value+" --resolution "+$q_struct["resolution"].value+" --depth "+$q_struct["depth"].value
  return result
end

# Construct ks network line

def get_ks_network()
  if $q_struct["bootproto"].value == "dhcp"
    result = "--device "+$q_struct["nic"].value+" --bootproto "+$q_struct["bootproto"].value
  else
    client_ip = $q_struct["ip"].value
    client_name = $q_struct["hostname"].value
    gateway = get_ipv4_default_route(client_ip)
    result = "--device "+$q_struct["nic"].value+" --bootproto "+$q_struct["bootproto"].value+" --ip "+client_ip+" --netmask "+$default_netmask+" --gateway "+gateway+" --nameserver "+$default_nameserver+" --hostname "+client_name
  end
  return result
end

# Set network

def set_ks_network()
  if $q_struct["bootproto"].value == "dhcp"
    $q_struct["ip"].ask = "no"
    $q_struct["ip"].type = ""
    $q_struct["hostname"].ask = "no"
    $q_struct["hostname"].type = ""
  end
  return
end

# Construct ks password line

def get_ks_password()
  result = "--iscrypted "+$q_struct["crypt"].value.to_s
  return result
end

# Construct admin ks password line

def get_ks_admin_password()
  result = "--name = "+$q_struct["adminuser"].value+" --groups="+$q_struct["admingroup"].value+" --homedir="+$q_struct["adminhome"].value+" --password="+$q_struct["admincrypt"].value.to_s+" --iscrypted --shell="+$q_struct["adminshell"].value+" --uid="+$q_struct["adminuid"].value
  return result
end

# Construct ks bootloader line

def get_ks_bootloader()
  result = "--location="+$q_struct["bootstrap"].value
  return result
end

# Construct ks clear  partition line

def get_ks_clearpart()
  result = "--all --drives="+$q_struct["bootdevice"].value+" --initlabel"
  return result
end

# Construct ks boot partition line

def get_ks_bootpart()
  result = $q_struct["bootmount"].value+" --fstype "+$q_struct["bootfs"].value+" --size = "+$q_struct["bootsize"].value+" --ondisk="+$q_struct["bootdevice"].value
  return result
end

# Construct ks volume partition line

def get_ks_volpart()
  result = $q_struct["volname"].value+" --size = "+$q_struct["volsize"].value+" --grow --ondisk="+$q_struct["bootdevice"].value
  return result
end

# Construct ks volume group line

def get_ks_volgroup()
  result = $q_struct["volgroupname"].value+" --pesize = "+$q_struct["pesize"].value+" "+$q_struct["volname"].value
  return result
end

# Construct ks log swap line

def get_ks_logswap()
  result = "swap --fstype swap --name = "+$q_struct["swapvol"].value+" --vgname = "+$q_struct["volgroupname"].value+" --size = "+$q_struct["swapmin"].value+" --grow --maxsize = "+$q_struct["swapmax"].value
  return result
end

# Construct ks log root line

def get_ks_logroot()
  result = "/ --fstype "+$q_struct["rootfs"].value+" --name = "+$q_struct["rootvol"].value+" --vgname = "+$q_struct["volgroupname"].value+" --size = "+$q_struct["rootsize"].value+" --grow"
  return result
end

# Get install url

def get_ks_install_url(service_name)
  install_url = "--url=http://"+$default_host+"/"+service_name
  return install_url
end

# Get kickstart header

def get_ks_header(client_name)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+client_name+" "+version
  return header
end

# Populate ks questions

def populate_ks_questions(service_name,client_name,client_ip)
  $q_struct = {}
  $q_order  = []

  name = "ks_header"
  config = Ks.new(
    type      = "output",
    question  = "Kickstart file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_ks_header(client_name),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "console"
  config = Ks.new(
    type      = "output",
    question  = "Console type",
    ask       = "yes",
    parameter = "",
    value     = "text",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install_type"
  config = Ks.new(
    type      = "output",
    question  = "Install type",
    ask       = "yes",
    parameter = "",
    value     = "install",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install_method"
  config = Ks.new(
    type      = "output",
    question  = "Install Medium",
    ask       = "yes",
    parameter = "",
    value     = "cdrom",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "url"
  config = Ks.new(
    type      = "output",
    question  = "Install Medium",
    ask       = "yes",
    parameter = "url",
    value     = get_ks_install_url(service_name),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "install_language"
  config = Ks.new(
    type      = "output",
    question  = "Install Language",
    ask       = "yes",
    parameter = "lang",
    value     = "en_US.UTF-8",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "support_language"
  config = Ks.new(
    type      = "output",
    question  = "Support Language",
    ask       = "yes",
    parameter = "langsupport",
    value     = get_ks_language(),
    valid     = "",
    eval      = "get_ks_language()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "keyboard"
  config = Ks.new(
    type      = "output",
    question  = "Keyboard",
    ask       = "yes",
    parameter = "keyboard",
    value     = "us",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "videocard"
  config = Ks.new(
    type      = "",
    question  = "Video Card",
    ask       = "yes",
    parameter = "",
    value     = "VMWare",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "videoram"
  config = Ks.new(
    type      = "",
    question  = "Video RAM",
    ask       = "yes",
    parameter = "",
    value     = "16384",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "hsync"
  config = Ks.new(
    type      = "",
    question  = "Horizontal Sync",
    ask       = "yes",
    parameter = "",
    value     = "31.5-37.9",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config

  name = "vsync"
  config = Ks.new(
    type      = "",
    question  = "Vertical Sync",
    ask       = "yes",
    parameter = "",
    value     = "50-70",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "resolution"
  config = Ks.new(
    type      = "",
    question  = "Resolution",
    ask       = "yes",
    parameter = "",
    value     = "800x600",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "depth"
  config = Ks.new(
    type      = "",
    question  = "Bit Depth",
    ask       = "yes",
    parameter = "",
    value     = "16",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "xconfig"
  config = Ks.new(
    type      = "",
    question  = "Xconfig",
    ask       = "yes",
    parameter = "xconfig",
    value     = get_ks_xconfig(),
    valid     = "",
    eval      = "get_ks_xconfig()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "nic"
  config = Ks.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "eth0",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootproto"
  config = Ks.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "set_ks_network()"
    )
  $q_struct[name] = config
  $q_order.push(name)

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

  name = "network"
  config = Ks.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_ks_network()",
    valid     = "",
    eval      = "get_ks_network()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "password"
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

  name = "crypt"
  config = Ks.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = get_password_crypt($default_root_password),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootpw"
  config = Ks.new(
    type      = "output",
    question  = "Root Password Configuration",
    parameter = "rootpw",
    value     = get_ks_password(),
    valid     = "",
    eval      = "get_ks_password()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "adminuser"
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

  name = "adminuid"
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

  name = "adminshell"
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

  name = "adminhome"
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

  name = "admingroup"
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

  name = "adminpassword"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password",
    ask       = "yes",
    parameter = "",
    value     = $default_root_password,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admincrypt"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = get_password_crypt($default_admin_password),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "selinux"
  config = Ks.new(
    type      = "output",
    question  = "SELinux Configuration",
    ask       = "yes",
    parameter = "selinux",
    value     = "--enforcing",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "authconfig"
  config = Ks.new(
    type      = "output",
    question  = "SELinux Configuration",
    parameter = "authconfig",
    value     = "--enableshadow --enablemd5",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timezone"
  config = Ks.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = "Australia/Melbourne",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootstrap"
  config = Ks.new(
    type      = "",
    question  = "Bootstrap",
    ask       = "yes",
    parameter = "",
    value     = "mbr",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootloader"
  config = Ks.new(
    type      = "output",
    question  = "Bootloader",
    ask       = "yes",
    parameter = "bootloader",
    value     = get_ks_bootloader(),
    valid     = "",
    eval      = "get_ks_bootloader()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootdevice"
  config = Ks.new(
    type      = "",
    question  = "Boot Device",
    ask       = "yes",
    parameter = "",
    value     = "sda",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "clearpart"
  config = Ks.new(
    type      = "output",
    question  = "Clear Parition",
    ask       = "yes",
    parameter = "clearpart",
    value     = get_ks_clearpart(),
    valid     = "",
    eval      = "get_ks_clearpart()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootmount"
  config = Ks.new(
    type      = "",
    question  = "Boot Mount Point",
    ask       = "yes",
    parameter = "",
    value     = "/boot",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootfs"
  config = Ks.new(
    type      = "",
    question  = "Boot Filesystem",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootsize"
  config = Ks.new(
    type      = "",
    question  = "Boot Size",
    ask       = "yes",
    parameter = "",
    value     = "100",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bootpart"
  config = Ks.new(
    type      = "output",
    question  = "Clear Parition",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_bootpart(),
    valid     = "",
    eval      = "get_ks_bootpart()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "volname"
  config = Ks.new(
    type      = "",
    question  = "Physical Volume Name",
    parameter = "",
    value     = "pv.2",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "volsize"
  config = Ks.new(
    type      = "",
    question  = "Physical Volume Size",
    ask       = "yes",
    parameter = "",
    value     = "0",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "volpart"
  config = Ks.new(
    type      = "output",
    question  = "Physical Volume Configuration",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_volpart(),
    valid     = "",
    eval      = "get_ks_volpart()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "volgroupname"
  config = Ks.new(
    type      = "",
    question  = "Volume Group Name",
    ask       = "yes",
    parameter = "",
    value     = "VolGroup00",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "pesize"
  config = Ks.new(
    type      = "",
    question  = "Physical Extent Size",
    ask       = "yes",
    parameter = "",
    value     = "32768",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "volgroup"
  config = Ks.new(
    type      = "output",
    question  = "Volume Group Configuration",
    ask       = "yes",
    parameter = "volgroup",
    value     = get_ks_volgroup(),
    valid     = "",
    eval      = "get_ks_volgroup()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "swapmin"
  config = Ks.new(
    type      = "",
    question  = "Minimum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "512",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "swapmax"
  config = Ks.new(
    type      = "",
    question  = "Maximum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "1024",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "swapvol"
  config = Ks.new(
    type      = "",
    question  = "Swap Volume Name",
    parameter = "",
    value     = "LogVol01",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "logswap"
  config = Ks.new(
    type      = "output",
    question  = "Swap Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logswap(),
    valid     = "",
    eval      = "get_ks_logswap()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootfs"
  config = Ks.new(
    type      = "",
    question  = "Root Filesystem",
    ask       = "yes",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootvol"
  config = Ks.new(
    type      = "",
    question  = "Root Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "LogVol00",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootsize"
  config = Ks.new(
    type      = "",
    question  = "Root Size",
    ask       = "yes",
    parameter = "",
    value     = "1024",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "logroot"
  config = Ks.new(
    type      = "output",
    question  = "Root Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logroot(),
    valid     = "",
    eval      = "get_ks_logroot()"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "finish"
  config = Ks.new(
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

