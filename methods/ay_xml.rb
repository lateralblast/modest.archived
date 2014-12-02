
# Do Autoyast XML

# Create a struct for users

User  = Struct.new(:fullname, :gid, :home, :expire, :flag, :inact, :max, :min, :warn, :shell, :uid, :user_password, :username)
Group = Struct.new(:gid, :group_password, :groupname, :userlist)
Inetd = Struct.new(:enabled, :iid, :protocol, :script, :server, :service)

# Populate hosts

def populate_ay_hosts(client_name,client_ip)
  hosts = []
  hosts.push("127.0.0.1,localhost")
  hosts.push("#{client_ip},#{client_name},#{client_name}.#{$default_domain}")
  hosts.push("::1,localhost ipv6-localhost ipv6-loopback")
  hosts.push("fe00::0,ipv6-localnet")
  hosts.push("ff00::0,ipv6-mcastprefix")
  hosts.push("ff02::1,ipv6-allnodes")
  hosts.push("ff02::2,ipv6-allrouters")
  hosts.push("ff02::3,ipv6-allhosts")
  return hosts
end

# Populate inetd information

def populate_ay_inetd()
  $i_struct = {}
  $i_order  = []

  service = "chargen"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "chargen-udp"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "udp",
    script   = service,
    server   = "",
    service  = "chargen"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "cups-lpd"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/usr/lib64/cups/daemon/cups-lpd",
    service  = "printer"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "cvs"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/usr/bin/cvs",
    service  = "cvspserver"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "daytime"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "daytime-udp"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "udp",
    script   = service,
    server   = "",
    service  = "daytime"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "discard"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "discard-udp"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "udp",
    script   = service,
    server   = "",
    service  = "discard"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "echo"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "echo-udp"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "udp",
    script   = service,
    server   = "",
    service  = "echo-udp"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "netstat"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/bin/"+service,
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "rsync"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/usr/sbin/"+service+"d",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "servers"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "services"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "swat"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/usr/sbin/"+service,
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "systat"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "/bin/ps",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "time"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "tcp",
    script   = service,
    server   = "",
    service  = service
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "time-udp"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/"+service,
    protocol = "udp",
    script   = service,
    server   = "",
    service  = "time"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnc1"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "1:/etc/xinetd.d/vnc",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/Xvnc",
    service  = "vnc1"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnc2"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "16:/etc/xinetd.d/vnc",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/Xvnc",
    service  = "vnc2"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnc3"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "31:/etc/xinetd.d/vnc3",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/Xvnc",
    service  = "vnc3"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnchttpd1"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "46:/etc/xinetd.d/vnc",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/vnc_inetd_httpd",
    service  = "vnchttpd1"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnchttpd2"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "61:/etc/xinetd.d/vnchttpd2",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/vnc_inetd_httpd",
    service  = "vnchttpd2"
    )
  $i_order.push(service)
  $i_struct[service] = config

  service = "vnchttpd3"
  config  = Inetd.new(
    enabled  = "false",
    iid      = "76:/etc/xinetd.d/vnchttpd3",
    protocol = "tcp",
    script   = "vnc",
    server   = "/usr/bin/vnc_inetd_httpd",
    service  = "vnchttpd3"
    )
  $i_order.push(service)
  $i_struct[service] = config

  return
end


# Populate Group information

def populate_ay_groups()
  $g_struct = {}
  $g_order  = []

  group  = "user"
  config = Group.new(
    gid            = "100",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "floppy"
  config = Group.new(
    gid            = "19",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "bin"
  config = Group.new(
    gid            = "1",
    group_password = "x",
    groupname      = group,
    userlist       = "daemon"
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "xok"
  config = Group.new(
    gid            = "41",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "nobody"
  config = Group.new(
    gid            = "65535",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "modem"
  config = Group.new(
    gid            = "43",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "lp"
  config = Group.new(
    gid            = "7",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "tty"
  config = Group.new(
    gid            = "5",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "postfix"
  config = Group.new(
    gid            = "51",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "uuid"
  config = Group.new(
    gid            = "104",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "gdm"
  config = Group.new(
    gid            = "111",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "nogroup"
  config = Group.new(
    gid            = "65534",
    group_password = "x",
    groupname      = group,
    userlist       = "nobody"
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "maildrop"
  config = Group.new(
    gid            = "59",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "messagebus"
  config = Group.new(
    gid            = "101",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "video"
  config = Group.new(
    gid            = "33",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "sys"
  config = Group.new(
    gid            = "3",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "shadow"
  config = Group.new(
    gid            = "15",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "console"
  config = Group.new(
    gid            = "21",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "cdrom"
  config = Group.new(
    gid            = "20",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "haldaemon"
  config = Group.new(
    gid            = "102",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "trusted"
  config = Group.new(
    gid            = "42",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "puppet"
  config = Group.new(
    gid            = "105",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "dialout"
  config = Group.new(
    gid            = "16",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "polkituser"
  config = Group.new(
    gid            = "106",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "pulse"
  config = Group.new(
    gid            = "100",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "wheel"
  config = Group.new(
    gid            = "10",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "www"
  config = Group.new(
    gid            = "8",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "games"
  config = Group.new(
    gid            = "40",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "disk"
  config = Group.new(
    gid            = "6",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "audio"
  config = Group.new(
    gid            = "17",
    group_password = "x",
    groupname      = group,
    userlist       = "pulse"
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "suse-ncc"
  config = Group.new(
    gid            = "110",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "ftp"
  config = Group.new(
    gid            = "49",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "at"
  config = Group.new(
    gid            = "25",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "tape"
  config = Group.new(
    gid            = "103",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "kmem"
  config = Group.new(
    gid            = "9",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "public"
  config = Group.new(
    gid            = "32",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "root"
  config = Group.new(
    gid            = "0",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "mail"
  config = Group.new(
    gid            = "12",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "daemon"
  config = Group.new(
    gid            = "2",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "ntp"
  config = Group.new(
    gid            = "107",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "uucp"
  config = Group.new(
    gid            = "14",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "pulse-access"
  config = Group.new(
    gid            = "109",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "ntadmin"
  config = Group.new(
    gid            = "72",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "man"
  config = Group.new(
    gid            = "62",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "utmp"
  config = Group.new(
    gid            = "22",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "news"
  config = Group.new(
    gid            = "13",
    group_password = "x",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  group  = "sshd"
  config = Group.new(
    gid            = "65",
    group_password = "!",
    groupname      = group,
    userlist       = ""
    )
  $g_order.push(group)
  $g_struct[group] = config

  return
end

# Populate list of packages to add

def populate_ay_add_packages()
  add_packages = []
  add_packages.push("at-spi-32bit")
  add_packages.push("cyrus-sasl-32bit")
  add_packages.push("dbus-1-32bit")
  add_packages.push("dbus-1-glib-32bit")
  add_packages.push("gdbm-32bit")
  add_packages.push("libFLAC8-32bit")
  add_packages.push("libbonobo-32bit")
  add_packages.push("libbz2-1-32bit")
  add_packages.push("libcanberra-gtk-32bit")
  add_packages.push("libcanberra-gtk0-32bit")
  add_packages.push("libcanberra0-32bit")
  add_packages.push("libcroco-0_6-3-32bit")
  add_packages.push("libdb-4_5-32bit")
  add_packages.push("libgsf-1-114-32bit")
  add_packages.push("libgstreamer-0_10-0-32bit")
  add_packages.push("libgthread-2_0-0-32bit")
  add_packages.push("libidl-32bit")
  add_packages.push("libldap-2_4-2-32bit")
  add_packages.push("libltdl7-32bit")
  add_packages.push("libogg0-32bit")
  add_packages.push("libproxy0-config-gnome")
  add_packages.push("libpulse0-32bit")
  add_packages.push("libpython2_6-1_0-32bit")
  add_packages.push("librsvg-32bit")
  add_packages.push("libsndfile-32bit")
  add_packages.push("libtalloc2-32bit")
  add_packages.push("libtdb1-32bit")
  add_packages.push("libvorbis-32bit")
  add_packages.push("libxml2-32bit")
  add_packages.push("orbit2-32bit")
  add_packages.push("samba-client-32bit")
  add_packages.push("sles-manuals_en")
  add_packages.push("tcpd-32bit")
  add_packages.push("xorg-x11-driver-video-radeonhd")
  add_packages.push("yast2-trans-en_US")
  return add_packages
end

# Populate list of packages to remove

def populate_ay_remove_packages()
  remove_packages = []
  remove_packages.push("cups-autoconfig")
  remove_packages.push("cups-drivers")
  remove_packages.push("emacs-nox")
  remove_packages.push("filters")
  remove_packages.push("gutenprint")
  remove_packages.push("libqt4-sql-sqlite")
  remove_packages.push("lprng")
  remove_packages.push("manufacturer-PPDs")
  remove_packages.push("pcmciautils")
  remove_packages.push("portmap")
  remove_packages.push("rsyslog")
  remove_packages.push("sendmail")
  remove_packages.push("susehelp_de")
  remove_packages.push("yast2-control-center-qt")
  return remove_packages
end

# Populate patterns

def populate_ay_patterns(service_name)
  patterns = []
  patterns.push("Basis-Devel")
  patterns.push("Minimal")
  patterns.push("base")
  if !service_name.match(/sles_12/)
    patterns.push("gnome")
    patterns.push("print_server")
  end
  patterns.push("x11")
  return patterns
end

# Populate users

def populate_ay_users()

  $u_struct = {}
  $u_order  = []

  user   = $default_admin_user
  config = User.new(
    fullname      = $default_admin_name,
    gid           = "100",
    home          = $default_admin_home,
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = $default_admin_shell,
    uid           = "",
    user_password = $q_struct["admin_crypt"].value,
    username      = $default_admin_user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "games"
  config = User.new(
    fullname      = "Games account",
    gid           = "100",
    home          = "/var/games",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "bin"
  config = User.new(
    fullname      = "bin",
    gid           = "1",
    home          = "bin",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "nobody"
  config = User.new(
    fullname      = "nobody",
    gid           = "65533",
    home          = "/var/lib/nobody",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "",
    user_password = "",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "lp"
  config = User.new(
    fullname      = "Printing daemon",
    gid           = "7",
    home          = "/var/spool/lpd",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "4",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "uuid"
  config = User.new(
    fullname      = "User for uuid",
    gid           = "104",
    home          = "/var/run/uuid",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "9999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "102",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user = "postfix"
  config = User.new(
    fullname      = "Postfix Daemon",
    gid           = "51",
    home          = "/var/spool/postfix",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "51",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "suse-ncc"
  config = User.new(
    fullname      = "Novell Customer Center User",
    gid           = "110",
    home          = "/var/lib/YaST2/suse-ncc-fakehome",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/bash",
    uid           = "106",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "ftp"
  config = User.new(
    fullname      = "FTP account",
    gid           = "49",
    home          = "/srv/ftp",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "40",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "gdm"
  config = User.new(
    fullname      = "Gnome Display Manager daemon",
    gid           = "111",
    home          = "/var/lib/gdm",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "9999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/bash",
    uid           = "107",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "at"
  config = User.new(
    fullname      = "Batch job daemon",
    gid           = "25",
    home          = "/var/spool/atjobs",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/bash",
    uid           = "25",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)


  user  = "root"
  config = User.new(
    fullname      = "root",
    gid           = "0",
    home          = "/root",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "0",
    user_password = $q_struct["root_crypt"].value,
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)


  user   = "mail"
  config = User.new(
    fullname      = "Mailer daemon",
    gid           = "12",
    home          = "",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/false",
    uid           = "8",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)


  user   = "daemon"
  config = User.new(
    fullname      = "Daemon",
    gid           = "2",
    home          = "/sbin",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "2",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)


  user   = "ntp"
  config = User.new(
    fullname      = "NTP daemon",
    gid           = "107",
    home          = "/var/lib/ntp",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "74",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)


  user   = "uucp"
  config = User.new(
    fullname      = "Unix-to-Unix CoPy system",
    gid           = "14",
    home          = "/etc/uucp",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "10",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "messagebus"
  config = User.new(
    fullname      = "User for D-Bus",
    gid           = "101",
    home          = "/var/run/dbus",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "100",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "haldaemon"
  config = User.new(
    fullname      = "User for haldaemon",
    gid           = "102",
    home          = "/var/run/hald",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "101",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "wwwrun"
  config = User.new(
    fullname      = "WWW daemon apache",
    gid           = "8",
    home          = "/var/lib/wwwrun",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/false",
    uid           = "30",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "puppet"
  config = User.new(
    fullname      = "Puppet daemon",
    gid           = "105",
    home          = "/var/lib/puppet",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "103",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "man"
  config = User.new(
    fullname      = "Manual pages viewer",
    gid           = "62",
    home          = "/var/cache/man",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/bash",
    uid           = "13",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "polkituser"
  config = User.new(
    fullname      = "PolicyKit",
    gid           = "106",
    home          = "/var/run/PolicyKit",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "104",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "news"
  config = User.new(
    fullname      = "News system",
    gid           = "13",
    home          = "/etc/news",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "",
    min           = "",
    warn          = "",
    shell         = "/bin/false",
    uid           = "9",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  user   = "pulse"
  config = User.new(
    fullname      = "PulseAudio daemon",
    gid           = "100",
    home          = "/var/lib/pulseaudio",
    expire        = "",
    flag          = "",
    inact         = "",
    max           = "99999",
    min           = "0",
    warn          = "7",
    shell         = "/bin/false",
    uid           = "105",
    user_password = "*",
    username      = user
    )
  $u_struct[user]=config
  $u_order.push(user)

  return
end

# Populate disabled http modules

def populate_ay_disabled_http_modules()
  disabled_http_modules = []
  disabled_http_modules.push("authz_host")
  disabled_http_modules.push("actions")
  disabled_http_modules.push("alias")
  disabled_http_modules.push("auth_basic")
  disabled_http_modules.push("authn_file")
  disabled_http_modules.push("authz_user")
  disabled_http_modules.push("authz_groupfile")
  disabled_http_modules.push("autoindex")
  disabled_http_modules.push("cgi")
  disabled_http_modules.push("dir")
  disabled_http_modules.push("include")
  disabled_http_modules.push("log_config")
  disabled_http_modules.push("mime")
  disabled_http_modules.push("negotiation")
  disabled_http_modules.push("setenvif")
  disabled_http_modules.push("status")
  disabled_http_modules.push("userdir")
  disabled_http_modules.push("asis")
  disabled_http_modules.push("imagemap")
  return disabled_http_modules
end

# Populate enabled http modules

def populate_ay_enabled_http_modules()
  enabled_http_modules = []
  return enabled_http_modules
end

# Populate services to disable

def populate_ay_disabled_services()
  disabled_services = []
  disabled_services.push("display_manager")
  return disabled_services
end

# Output client profile file

def output_ay_client_profile(client_name,client_ip,client_mac,output_file,service_name)
  populate_ay_users()
  populate_ay_groups()
  populate_ay_inetd()
  gateway               = get_ipv4_default_route(client_ip)
  xml_output            = []
  hosts                 = populate_ay_hosts(client_name,client_ip)
  add_packages          = populate_ay_add_packages()
  remove_packages       = populate_ay_remove_packages()
  patterns              = populate_ay_patterns(service_name)
  disable_services      = populate_ay_disabled_services()
  disabled_http_modules = populate_ay_disabled_http_modules()
  enabled_http_modules  = populate_ay_enabled_http_modules()
  xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
  xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.declare! :DOCTYPE, :profile
  xml.profile(:xmlns => "http://www.suse.com/1.0/yast2ns", :"xmlns:config" => "http://www.suse.com/1.0/configns") {
    xml.tag!("add-on") {
      xml.add_on_products(:"config:type" => "list")
    }
    xml.tag!("audit-laf") {
      xml.auditd {
        xml.action_mail_acct("root")
        xml.admin_space_left("50")
        xml.admin_space_left_action("SUSPEND")
        xml.disk_error_action("SUSPEND")
        xml.disk_full_action("SUSPEND")
        xml.disp_qos("lossy")
        xml.dispatcher("/sbin/audispd")
        xml.flush("INCREMENTAL")
        xml.freq("20")
        xml.log_file("/var/log/audit/audit.log")
        xml.log_format("RAW")
        xml.log_group("root")
        xml.max_log_file("5")
        xml.max_log_file_action("ROTATE")
        xml.name_format("NONE")
        xml.num_logs("4")
        xml.priority_boost("4")
        xml.space_left("75")
        xml.space_left_action("SYSLOG")
        xml.tcp_client_max_idle("0")
        xml.tcp_listen_queue("5")
      }
      xml.rules {
        xml.text!("# First rule - delete all\n")
        xml.text!("-D\n")
        xml.text!("# Make this bigger for busy systems\n")
        xml.text!("-b 320\n")
      }
    }
    xml.bootloader {
      xml.device_map(:"config:type" => "list") {
        xml.device_map_entry {
          xml.firmware("fd0")
          xml.linux("/dev/fd0")
        }
        xml.device_map_entry {
          xml.firmware("hd0")
          xml.linux("/dev/sda")
        }
      }
      xml.global {
        xml.activate("true")
        xml.boot_root("true")
        xml.default("SUSE Linux Enterprise Server")
        xml.generic_mbr("true")
        xml.gfxmenu("/boot/message")
        xml.lines_cache_id("3")
        xml.timeout("8",:"config:type" => "integer")
      }
      xml.initrd_modules(:"config:type" => "list") {
        xml.initrd_module {
          xml.module("mptspi")
        }
        xml.initrd_module {
          xml.module("ahci")
        }
        xml.initrd_module {
          xml.module("ata_piix")
        }
        xml.initrd_module {
          xml.module("ata_generic")
        }
        xml.initrd_module {
          xml.module("vmxnet3")
        }
        xml.initrd_module {
          xml.module("vmw_pvscsi")
        }
        xml.initrd_module {
          xml.module("vmxnet")
        }
      }
      if service_name.match(/sles_12/)
        xml.loader_type("grub2")
      else
        xml.loader_type("grub")
      end
      xml.sections(:"config:type" => "list") {
        #xml.section {
        #  xml.append("resume=/dev/sda1 splash=silent showopts")
        #  xml.image("/boot/vmlinuz-3.0.13-0.27-default")
        #  xml.initial("1")
        #  xml.initrd("/boot/initrd-3.0.13-0.27-default")
        #  xml.lines_cache_id("0")
        #  xml.name("SUSE Linux Enterprise Server 11 SP2 - 3.0.13-0.27")
        #  xml.original_name("linux")
        #  xml.root("/dev/sda2")
        #  xml.type("image")
        #}
        #xml.section {
        #  xml.append("showopts ide=nodma apm=off noresume edd=off powersaved=off nohz=off highres=off processor.max_cstate=1 nomodeset x11failsafe")
        #  xml.image("/boot/vmlinuz-3.0.13-0.27-default")
        #  xml.initrd("/boot/initrd-3.0.13-0.27-default")
        #  xml.lines_cache_id("1")
        #  xml.name("Failsafe -- SUSE Linux Enterprise Server 11 SP2 - 3.0.13-0.27")
        #  xml.original_name("failsafe")
        #  xml.root("/dev/sda2")
        #  xml.type("image")
        #}
        #xml.section {
        #  xml.blockoffset("1")
        #  xml.chainloader("/dev/fd0")
        #  xml.lines_cache_id("2")
        #  xml.name("Floppy")
        #  xml.noverifyroot("true")
        #  xml.original_name("floppy")
        #  xml.root("")
        #  xml.type("other")
        #}
      }
    }
    xml.ca_mgm {
      xml.CAName("YaST_Default_CA")
      xml.ca_commonName("YaST Default CA (site)")
      xml.country($default_country)
      xml.importCertificate("false", :'config:type' => "boolean")
      xml.locality("")
      xml.organisation("")
      xml.organisationUnit("")
      xml.password("ENTER PASSWORD HERE")
      xml.server_commonName(client_name)
      xml.server_email("postmaster@site")
      xml.state("")
      xml.takeLocalServerName("true", :'config:type' => "boolean")
    }
    xml.deploy_image {
      xml.image_installation("false", :'config:type' => "boolean")
    }
    xml.tag!("dhcp-server") {
      xml.allowed_interfaces(:"config:type" => "list")
      xml.chroot("1")
      xml.other_options("")
      xml.settings(:"config:type" => "list") {
        xml.settings_entry {
          xml.children(:"config:type" => "list")
          xml.directives(:"config:type" => "list")
          xml.id("")
          xml.options(:"config:type" => "list")
          xml.parent_id("")
          xml.parent_type("")
          xml.type("")
        }
      }
      xml.start_service("0")
      xml.use_ldap("0")
    }
    xml.tag!("dns-server") {
      xml.allowed_interfaces(:"config:type" => "list")
      xml.chroot("1")
      xml.logging(:"config:type" => "list")
      xml.options(:"config:type" => "list") {
        xml.option {
          xml.key("forwarders")
          xml.value("")
        }
      }
      xml.start_service("0")
      xml.use_ldap("0")
      xml.zones(:"config:type" => "list")
    }
    xml.firewall {
      xml.FW_DEV_DMZ("")
      xml.FW_DEV_EXT("")
      xml.FW_DEV_INT("")
      xml.enable_firewall("false", :'config:type' => "boolean")
      xml.start_firewall("false", :'config:type' => "boolean")
    }
    xml.tag!("ftp-server") {
      xml.AnonAuthen("1")
      xml.AnonCreatDirs("NO")
      xml.AnonMaxRate("0")
      xml.AnonReadOnly("YES")
      xml.AntiWarez("YES")
      xml.Banner("Welcome message")
      xml.CertFile("")
      xml.ChrootEnable("NO")
      xml.EnableUpload("NO")
      xml.FTPUser("ftp")
      xml.FtpDirAnon("/srv/ftp")
      xml.FtpDirLocal("")
      xml.GuestUser("")
      xml.LocalMaxRate("0")
      xml.MaxClientsNumber("10")
      xml.MaxClientsPerIP("3")
      xml.MaxIdleTime("15")
      xml.PasMaxPort("40500")
      xml.PasMinPort("40000")
      xml.PassiveMode("YES")
      xml.SSL("0")
      xml.SSLEnable("NO")
      xml.SSLv2("NO")
      xml.SSLv3("NO")
      xml.StartDaemon("0")
      xml.StartXinetd("NO")
      xml.TLS("YES")
      xml.Umask("")
      xml.UmaskAnon("")
      xml.UmaskLocal("")
      xml.VerboseLogging("NO")
      xml.VirtualUser("NO")
    }
    xml.general {
      xml.tag!("ask-list", :"config:type" => "list")
      xml.mode {
        xml.confirm("false", :"config:type" => "boolean")
      }
      xml.mouse {
        xml.id("none")
      }
      xml.proposals(:"config:type" => "list")
      xml.tag!("signature-handling") {
        xml.accept_file_without_checksum("true", :"config:type" => "boolean")
        xml.accept_non_trusted_gpg_key("true", :"config:type" => "boolean")
        xml.accept_unknown_gpg_key("true", :"config:type" => "boolean")
        xml.accept_unsigned_file("true", :"config:type" => "boolean")
        xml.accept_verification_failed("false", :"config:type" => "boolean")
        xml.import_gpg_key("true", :"config:type" => "boolean")
      }
      xml.storage()
    }
    xml.groups(:"config:type" => "list") {
      $g_order.each do |group|
        xml.group {
          xml.encrypted("true", :"config:type" => "boolean")
          xml.gid($g_struct[group].gid)
          xml.group_password($g_struct[group].group_password)
          xml.groupname($g_struct[group].groupname)
          xml.userlist($g_struct[group].userlist)
        }
      end
    }
    xml.host {
      xml.hosts(:"config:type" => "list") {
        hosts.each do |host|
          xml.hosts_entry {
            (host_address,name) = host.split(/,/)
            xml.host_address(host_address)
            xml.names(:"config:type" => "list") {
              xml.name(name)
            }
          }
        end
      }
    }
    xml.tag!("http-server") {
      xml.Listen(:"config:type" => "list")
      xml.hosts(:"config:type" => "list")
      xml.modules(:"config:type" => "list") {
        disabled_http_modules.each do |name|
          xml.module_entry {
            xml.change("disable")
            xml.default("1")
            xml.name(name)
          }
        end
        enabled_http_modules.each do |name|
          xml.module_entry {
            xml.change("enabled")
            xml.default("1")
            xml.name(name)
          }
        end
      }
    }
    xml.inetd {
      xml.last_created("0", :"config:type" => "integer")
      xml.netd_conf(:"config:type" => "list") {
        $i_order.each do |service|
          xml.conf {
            xml.enabled($i_struct[service].enabled, :"config:type" => "boolean")
            xml.iid($i_struct[service].iid)
            xml.protocol($i_struct[service].protocol)
            xml.script($i_struct[service].script)
            xml.server($i_struct[service].server)
            xml.service($i_struct[service].service)
          }
        end
      }
    }
    xml.tag!("iscsi-client") {
      xml.initiatorname("")
      xml.targets(:"config:type" => "list")
      xml.version("1.0")
    }
    xml.kdump {
      xml.add_crash_kernel("false", :"config:type" => "boolean")
      xml.crash_kernel("128M-:64M")
      xml.general {
        xml.KDUMPTOOL_FLAGS("")
        xml.KDUMP_COMMANDLINE("")
        xml.KDUMP_COMMANDLINE_APPEND("")
        xml.KDUMP_CONTINUE_ON_ERROR("false")
        xml.KDUMP_COPY_KERNEL("yes")
        xml.KDUMP_DUMPFORMAT("compressed")
        xml.KDUMP_DUMPLEVEL("0")
        xml.KDUMP_FREE_DISK_SIZE("64")
        xml.KDUMP_HOST_KEY("")
        xml.KDUMP_IMMEDIATE_REBOOT("yes")
        xml.KDUMP_KEEP_OLD_DUMPS("5")
        xml.KDUMP_KERNELVER("")
        xml.KDUMP_NETCONFIG("auto")
        xml.KDUMP_NOTIFICATION_CC("")
        xml.KDUMP_NOTIFICATION_TO("")
        xml.KDUMP_POSTSCRIPT("")
        xml.KDUMP_PRESCRIPT("")
        xml.KDUMP_REQUIRED_PROGRAMS("")
        xml.KDUMP_SAVEDIR("file:///var/crash")
        xml.KDUMP_SMTP_PASSWORD("")
        xml.KDUMP_SMTP_SERVER("")
        xml.KDUMP_SMTP_USER("")
        xml.KDUMP_TRANSFER("")
        xml.KDUMP_VERBOSE("3")
        xml.KEXEC_OPTIONS("")
      }
    }
    xml.kerberos {
      xml.kerberos_client {
        xml.ExpertSettings {
          xml.external("sshd")
          xml.use_shmem("sshd")
        }
        xml.clockskew("300")
        xml.default_domain("site")
        xml.default_realm("SITE")
        xml.forwardable("true", :"config:type" => "boolean")
        xml.ignore_unknown("true", :"config:type" => "boolean")
        xml.kdc_server("")
        xml.minimum_uid("1")
        xml.proxiable("false", :"config:type" => "boolean")
        xml.renew_lifetime("1d")
        xml.ssh_support("false", :"config:type" => "boolean")
        xml.ticket_lifetime("1d")
      }
      xml.pam_login {
        xml.sssd("false", :"config:type" => "boolean")
        xml.use_kerberos("false", :"config:type" => "boolean")
      }
    }
    xml.keyboard {
      xml.keymap("english-us")
    }
    xml.language {
      xml.language($default_language)
      xml.languages($default_language)
    }
    xml.ldap {
      xml.base_config_dn("")
      xml.bind_dn("")
      xml.create_ldap("false", :"config:type" => "boolean")
      xml.file_server("false", :"config:type" => "boolean")
      xml.ldap_domain("dc=example,dc=com")
      xml.ldap_server("127.0.0.1")
      xml.ldap_tls("true", :"config:type" => "boolean")
      xml.ldap_v2("false", :"config:type" => "boolean")
      xml.login_enabled("true", :"config:type" => "boolean")
      xml.member_attribute("member")
      xml.mkhomedir("false", :"config:type" => "boolean")
      xml.pam_password("exop")
      xml.sssd("false", :"config:type" => "boolean")
      xml.start_autofs("false", :"config:type" => "boolean")
      xml.start_ldap("false", :"config:type" => "boolean")
    }
    xml.login_settings()
    xml.mail {
      xml.aliases(:"config:type" => "list") {
        $u_order.each do |user|
          xml.alias {
            xml.alias(user)
            xml.comment("")
            xml.destinations("root")
          }
        end
      }
      xml.connection_type("permanent", :"config:type" => "symbol")
      xml.listen_remote("false", :"config:type" => "boolean")
      xml.mta("postfix", :"config:type" => "symbol")
      xml.postfix_mda("local", :"config:type" => "symbol")
      xml.smtp_use_TLS("no")
      xml.use_amavis("false", :"config:type" => "boolean")
      xml.use_dkim("false", :"config:type" => "boolean")
    }
    xml.networking {
      xml.dhcp_options {
        xml.dhclient_client_id("")
        xml.dhclient_hostname_option("AUTO")
      }
      xml.dns {
        xml.dhcp_hostname("false", :"config:type" => "boolean")
        xml.domain($default_domain)
        xml.hostname(client_name)
        xml.nameservers(:"config:type" => "list") {
          xml.nameserver($default_nameserver)
        }
        xml.resolv_conf_policy("auto")
        xml.write_hostname("false", :"config:type" => "boolean")
      }
      xml.interfaces(:"config:type" => "list") {
        xml.interface {
          xml.bootproto("static")
          xml.device($q_struct["nic"].value)
          xml.ipaddr(client_ip)
          xml.netmask($default_netmask)
          xml.startmode("auto")
          xml.usercontrol("no")
        }
        xml.interface {
          xml.aliases {
            xml.alias2 {
              xml.IPADDR("127.0.0.2")
              xml.NETMASK("255.0.0.0")
              xml.PREFIXLEN("8")
            }
          }
          xml.broadcast("127.255.255.255")
          xml.device("lo")
          xml.firewall("no")
          xml.ipaddr("127.0.0.1")
          xml.netmask("255.0.0.0")
          xml.network("127.0.0.0")
          xml.prefixlen("8")
          xml.startmode("auto")
          xml.usercontrol("no")
        }
      }
      xml.managed("false", :"config:type" => "boolean")
      xml.tag!("net-udev", :"config:type" => "list") {
        xml.rule {
          xml.name($q_struct["nic"].value)
          xml.rule("ATTR{address}")
          xml.value(client_mac)
        }
      }
      xml.routing {
        xml.ip_forward("false", :"config:type" => "boolean")
        xml.routes(:"config:type" => "list") {
          xml.route {
            xml.destination("default")
            xml.device("-")
            xml.gateway(gateway)
            xml.netmask("-")
          }
        }
      }
    }
    xml.nfs_server {
      xml.nfs_exports(:"config:type" => "list")
      xml.start_nfsserver("false", :"config:type" => "boolean")
    }
    xml.nis {
      xml.netconfig_policy("auto")
      xml.nis_broadcast("false", :"config:type" => "boolean")
      xml.nis_broken_server("false", :"config:type" => "boolean")
      xml.nis_domain("")
      xml.nis_local_only("false", :"config:type" => "boolean")
      xml.nis_options("")
      xml.nis_other_domains(:"config:type" => "list")
      xml.nis_servers(:"config:type" => "list")
      xml.slp_domain()
      xml.start_autofs("false", :"config:type" => "boolean")
      xml.start_nis("false", :"config:type" => "boolean")
    }
    xml.nis_server {
      xml.domain("")
      xml.maps_to_serve(:"config:type" => "list")
      xml.merge_passwd("false", :"config:type" => "boolean")
      xml.mingid("0",:"config:type" => "integer")
      xml.minuid("0",:"config:type" => "integer")
      xml.nopush("false", :"config:type" => "boolean")
      xml.pwd_chfn("false", :"config:type" => "boolean")
      xml.pwd_chsh("false", :"config:type" => "boolean")
      xml.pwd_srcdir("/etc")
      xml.securenets(:"config:type" => "list") {
        xml.securenet {
          xml.netmask("255.0.0.0")
          xml.network("127.0.0.0")
        }
      }
      xml.server_type("none")
      xml.slaves(:"config:type" => "list")
      xml.start_ypbind("false", :"config:type" => "boolean")
      xml.start_yppasswdd("false", :"config:type" => "boolean")
      xml.start_ypxfrd("false", :"config:type" => "boolean")
    }
    xml.tag!("ntp-client") {
      xml.ntp_policy("auto")
      xml.peers(:"config:type" => "list") {
        xml.peer {
          xml.address($default_timeserver)
          xml.fudge_oprions(" stratum 10")
          xml.options("")
          xml.type("__clock")
        }
        xml.peer {
          xml.address("var/lib/ntp/drift/ntp.drift ")
          xml.type("driftfile")
        }
        xml.peer {
          xml.address("/var/log/ntp   ")
          xml.options("")
          xml.type("logfile")
        }
        xml.peer {
          xml.address("etc/ntp.keys   ")
          xml.questions("")
          xml.type("keys")
        }
        xml.peer {
          xml.address("1      ")
          xml.options("")
          xml.type("trustedkey")
        }
        xml.peer {
          xml.address("1      ")
          xml.options("")
          xml.type("requestkey")
        }
      }
      xml.start_at_boot("false", :"config:type" => "boolean")
      xml.start_in_chroot("true", :"config:type" => "boolean")
    }
    xml.partitioning(:"config:type" => "list") {
      xml.drive {
        xml.device("/dev/sda")
        xml.initialize("true", :"config:type" => "boolean")
          xml.partitions(:"config:type" => "list") {
            xml.partition {
              xml.create("true",:"config:type" => "boolean")
              xml.crypt_fs("false",:"config:type" => "boolean")
              xml.filesystem("swap",:"config:type" => "symbol")
              xml.format("true",:"config:type" => "boolean")
              xml.fstopt("defaults")
              xml.loop_fs("false",:"config:type" => "boolean")
              xml.mount("swap")
              xml.mountby("device",:"config:type" => "symbol")
              xml.partition_id("130",:"config:type" => "integer")
              xml.partition_nr("1",:"config:type" => "integer")
              xml.raid_options()
              xml.resize("false",:"config:type" => "boolean")
              swap_size = Integer($q_struct["swapmax"].value)*1000*1000
              swap_size = swap_size.to_s
              xml.size(swap_size)
            }
            xml.partition {
              xml.create("true",:"config:type" => "boolean")
              xml.crypt_fs("false",:"config:type" => "boolean")
              xml.filesystem("ext3",:"config:type" => "symbol")
              xml.format("true",:"config:type" => "boolean")
              xml.fstopt("acl,user_xattr")
              xml.loop_fs("false",:"config:type" => "boolean")
              xml.mount("/")
              xml.mountby("device",:"config:type" => "symbol")
              xml.partition_id("131",:"config:type" => "integer")
              xml.partition_nr("2",:"config:type" => "integer")
              xml.raid_options()
              xml.resize("false",:"config:type" => "boolean")
              root_size = Integer($q_struct["rootsize"].value)*1000*1000*10
              root_size = root_size.to_s
              xml.size(root_size)
            }
          }
          xml.pesize("")
          xml.type("CT_DISK", :"config:type" => "symbol")
          xml.use("all")
      }
    }
    xml.tag!("power-management") {
      xml.global_settings {
        xml.SCHEME("")
      }
      xml.schemes(:"config:type" => "list") {
        xml.schema {
          xml.CPUFREQ_GOVERNOR("ondemand")
        }
        xml.schema {
          xml.CPUFREQ_GOVERNOR("performance")
        }
        xml.schema {
          xml.CPUFREQ_GOVERNOR("ondemand")
        }
      }
    }
    xml.printer {
    }
    xml.proxy {
    }
    xml.report {
      xml.errors {
        xml.log("true", :"config:type" => "boolean")
        xml.show("false", :"config:type" => "boolean")
        xml.timeout("0", :"config:type" => "integer")
      }
      xml.messages {
        xml.log("true", :"config:type" => "boolean")
        xml.show("true", :"config:type" => "boolean")
        xml.timeout("0", :"config:type" => "integer")
      }
      xml.warnings {
        xml.log("true", :"config:type" => "boolean")
        xml.show("true", :"config:type" => "boolean")
        xml.timeout("0", :"config:type" => "integer")
      }
      xml.yesno_messages {
        xml.log("true", :"config:type" => "boolean")
        xml.show("true", :"config:type" => "boolean")
        xml.timeout("0", :"config:type" => "integer")
      }
    }
    xml.runlevel {
      xml.default("5")
      disabled_services.each do |name|
        xml.service {
          xml.service_name(name)
          xml.service_status("disabled")
        }
      end
    }
    xml.tag!("samba-server") {
    }
    xml.security {
      xml.console_shutdown("reboot")
      xml.cracklib_dict_path("/usr/lib/cracklib_dict")
      xml.cwd_in_root_path("no")
      xml.cwd_in_user_path("no")
      xml.disable_restart_on_update("no")
      xml.disable_stop_on_removal("no")
      xml.displaymanager_remote_access("no")
      xml.displaymanager_root_login_remote("no")
      xml.displaymanager_shutdown("root")
      xml.displaymanager_xserver_tcp_port_6000_open("no")
      xml.enable_sysrq("176")
      xml.fail_delay("3")
      xml.gid_max("60000")
      xml.gid_min("1000")
      xml.group_encryption("md5")
      xml.ip_forward("no")
      xml.ip_tcp_syncookies("yes")
      xml.ipv6_forward("no")
      xml.lastlog_enab("yes")
      xml.obscure_checks_enab("yes")
      xml.pass_max_days("99999")
      xml.pass_min_days("0")
      xml.pass_min_len("5")
      xml.pass_warn_age("7")
      xml.passwd_encryption("blowfish")
      xml.passwd_remember_history("0")
      xml.passwd_use_cracklib("yes")
      xml.permission_security("easy")
      xml.run_updatedb_as("")
      xml.runlevel3_extra_services("insecure")
      xml.runlevel3_mandatory_services("insecure")
      xml.runlevel5_extra_services("insecure")
      xml.runlevel5_mandatory_services("insecure")
      xml.smtpd_listen_remote("no")
      xml.syslog_on_no_error("no")
      xml.system_gid_max("499")
      xml.system_gid_min("100")
      xml.system_uid_max("499")
      xml.system_uid_min("100")
      xml.systohc("yes")
      xml.uid_max("60000")
      xml.uid_min("1000")
      xml.useradd_cmd("/usr/sbin/useradd.local")
      xml.userdel_postcmd("/usr/sbin/userdel-post.local")
      xml.userdel_precmd("/usr/sbin/userdel-pre.local")
    }
    xml.software {
      xml.packages(:"config:type" => "list") {
        add_packages.each do |package|
          xml.package(package)
        end
      }
      xml.patterns(:"config:type" => "list") {
        patterns.each do |pattern|
          xml.pattern(pattern)
        end
      }
      xml.tag!("remove-packages", :"config:type" => "list") {
        remove_packages.each do |package|
          xml.package(package)
        end
      }
    }
    xml.sound {
    }
    xml.sshd {
      xml.config {
        xml.AcceptEnv(:"config:type" => "list") {
          xml.listentry("LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES ")
          xml.listentry("LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT ")
          xml.listentry("LC_IDENTIFICATION LC_ALL")
        }
        xml.PasswordAuthentication(:"config:type" => "list") {
          xml.listentry("no")
        }
        xml.Protocol(:"config:type" => "list") {
          xml.listentry("2")
        }
        xml.Subsystem(:"config:type" => "list") {
          xml.listentry("sftp\t/usr/lib64/ssh/sftp-server")
        }
        xml.UsePAM(:"config:type" => "list") {
          xml.listentry("yes")
        }
        xml.X11Forwarding(:"config:type" => "list") {
          xml.listentry("yes")
        }
      }
      xml.status("true", :"config:type" => "boolean")
    }
    xml.suse_register {
      xml.do_registration("false", :"config:type" => "boolean")
      xml.reg_server("")
      xml.reg_server_cert("")
      xml.register_regularly("false", :"config:type" => "boolean")
      xml.registration_data()
      xml.submit_hwdata("false", :"config:type" => "boolean")
      xml.submit_optional("false", :"config:type" => "boolean")
    }
    xml.timezone {
      xml.hwclock("UTC")
      xml.timezone($q_struct["timezone"].value)
    }
    xml.user_defaults {
      xml.expire("")
      xml.group("100")
      xml.groups("video,dialout")
      xml.home("/home")
      xml.inactive("-1")
      xml.shell("/bin/bash")
      xml.skel("/etc/skel")
      xml.umask("022")
    }
    xml.users(:"config:type" => "list") {
      $u_order.each do |user|
        xml.user {
          xml.encrypted("true", :"config:type" => "boolean")
          xml.fullname($u_struct[user].fullname)
          xml.gid($u_struct[user].gid)
          xml.home($u_struct[user].home)
          xml.password_settings {
            xml.expire($u_struct[user].expire)
            xml.flag($u_struct[user].flag)
            xml.inact($u_struct[user].inact)
            xml.max($u_struct[user].max)
            xml.min($u_struct[user].min)
            xml.warn($u_struct[user].warn)
          }
          xml.shell($u_struct[user].shell)
          xml.uid($u_struct[user].uid)
          xml.user_password($u_struct[user].user_password)
          xml.username($u_struct[user].username)
        }
      end
    }
    xml.x11 {
      xml.color_depth("8",:"config:type" => "integer")
      xml.display_manager("gdm")
      xml.enable_3d("true", :"config:type" => "boolean")
      xml.monitor {
        xml.display {
          xml.max_hsync("60",:"config:type" => "integer")
          xml.max_vsync("75",:"config:type" => "integer")
          xml.min_hsync("31",:"config:type" => "integer")
          xml.min_vsync("50",:"config:type" => "integer")
        }
        xml.monitor_device("Unknown")
        xml.monitor_vendor("Unknown")
      }
      xml.resolution("800x600 (SVGA)")
      xml.window_manager("")
    }
  }
  file=File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Validating:\tAutoYast XML configuration for "+client_name
  command = "xmllint #{output_file}"
  execute_command(message,command)
  return
end
