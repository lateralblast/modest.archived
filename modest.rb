#!/usr/bin/env ruby

# Name:         modest (Muti OS Deployment Engine Server Tool)
# Version:      0.6.2
# Release:      1
# License:      Open Source
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to automate creation of server configuration for
#               Solaris and other OS

# Additional notes:
#
# - Swapped Dir.exits for File.directory so ruby 2.x is not required
# - Swapped Dir.home for ENV["HOME"] so ruby 2.x is not required

require 'rubygems'
require 'getopt/std'
require 'builder'

# Set up some global variables/defaults

$script=$0
$options="F:a:c:d:e:f:i:l:n:r:z:ACDJKLPRSVWZtv"
$verbose_mode=0
$test_mode=0
$iso_base_dir="/export/isos"
$repo_base_dir="/export/repo"
$iso_mount_dir="/cdrom"
$ai_base_dir="/export/auto_install"
$work_dir=""
$tmp_dir=""
$alt_repo_name="alt"
$alt_prefix_name="solaris"
$home_dir=ENV["HOME"]
$default_zpool="rpool"
$default_ai_port="10081"
$default_host=""
$default_net="net0"
$default_timezone="Australia/Victoria"
$default_terminal="sun"
$default_keymap="US-English"
$default_environment="en_US.UTF-8"
$default_nameserver="8.8.8.8"
$default_netmask="255.255.255.0"
$default_search="local"
$default_files="files"
$default_hosts="files dns"
$default_root_password="XXXX"
$default_admin_password="YYYY"
$use_alt_repo=0
$destroy_fs=0
$use_defaults=0
$default_apache_allow=""
$default_admin_user="sysadmin"
$default_admin_group="wheel"
$default_admin_home="/export/home"
$default_admin_shell="/export/home"
$default_admin_uid="200"
$tftp_dir="/etc/netboot"

# Declare some package versions

$facter_version="1.7.4"
$hiera_version="1.3.0"
$puppet_version="3.4.1"

# Load methods

if File.directory?("./methods")
  file_list=Dir.entries("./methods")
  for file in file_list
    if file =~/rb$/
      require "./methods/#{file}"
    end
  end
end

# Print script usage information

def print_usage()
  puts ""
  puts "Usage: "+$script+" -["+$options+"]"
  puts ""
  puts "-h: Display usage"
  puts "-c: Create client"
  puts "-V: Display version"
  puts "-A: Configure AI"
  puts "-J: Configure Jumpstart"
  puts "-K: Configure Kicstart"
  puts "-a: Architecture"
  puts "-e: Client MAC Address"
  puts "-i: Clinet IP Address"
  puts "-S: Configure server"
  puts "-C: Configure client services"
  puts "-P: Puplisher server port number"
  puts "-H: Puplisher server Hostname/IP"
  puts "-t: Run it test mode (in client mode create files but don't import them)"
  puts "-v: Run in verbose mode"
  puts "-f: ISO file to use"
  puts "-F: Set location of ISOs (directory)"
  puts "-d: Delete client"
  puts "-n: Set service name"
  puts "-z: Delete service name"
  puts "-W: Update apache proxy entry for AI"
  puts "-R: Use alternate package repository (additional packages like puppet)"
  puts "-Z: Destroy ZFS filesystem as part of uninstallation"
  puts "-D: Use default values for questions"
  puts ""
  puts "Examples:"
  puts ""
  puts "Unconfigure AI service:\t\t"+$script+" -A -z sol_11_1"
  puts "Configure all AI services:\t"+$script+" -A -S"
  puts "Configure AI client services:\t"+$script+" -A -C -a i386"
  puts "Create AI client:\t\t"+$script+" -A -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
  puts "Enable AI proxy:\t\t"+$script+" -A -W -n sol_11_1"
  puts "Disable AI proxy:\t\t"+$script+" -A -W -z sol_11_1"
  puts "Delete AI client:\t\t"+$script+" -A -d sol11u01vm03"
  puts "Configure alternate repo:\t"+$script+" -A -R"
  puts "Unconfigure alternate repo:\t"+$script+" -A -R -z sol_11_1_alt"
  puts
  puts "Unconfigure KS service:\t\t"+$script+" -A -z rh_5_9"
  puts "Configure KS services:\t\t"+$script+" -K -S -l redhat"
  puts "Create KS client:\t\t"+$script+" -K -c centos59vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_9"
  puts "Configure KS client PXE:\t"+$script+" -K -P -c centos59vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_9"
  puts "Enable KS alias:\t\t"+$script+" -K -W -n centos_5_9"
  puts "Disable KS alias:\t\t"+$script+" -K -W -z centos_5_9"
  puts "Delete KS client:\t\t"+$script+" -K -d centos59vm01"
  puts "Import PXE files:\t\t"+$script+" -K -P -n centos_5_9"
  puts "Unconfigure KS client PXE:\t"+$script+" -K -P -d centos59vm01"
  puts "Configure alternate repo:\t"+$script+" -K -R -n centos_5_9"
  puts "Unconfigure alternate repo:\t"+$script+" -K -R -z centos_5_9"
  puts
  puts "List AI services:\t\t"+$script+" -A -S -L"
  puts "List AI clients:\t\t"+$script+" -A -L"
  puts "List KS services:\t\t"+$script+" -K -S -L"
  puts "List KS clients:\t\t"+$script+" -K -L"
  puts ""
  exit
end

# Get version

def get_version()
  file_array=IO.readlines $0
  version=file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager=file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name=file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version
end

# Print script version information

def print_version()
  version=get_version()
  puts name+" v. "+version+" "+packager
  exit
end

# Check local configuration
# Create work directory if it doesn't exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config()
  if !$work_dir.match(/[A-z]/)
    dir_name=File.basename($script,".*")
    id=%x[/usr/bin/id -u]
    id=Integer(id)
    if id == 0
      $work_dir="/opt/"+dir_name
    else
      $work_dir=$home_dir+"/."+dir_name
    end
  end
  if $verbose_mode == 1
    puts "Information:\tSetting work directory to "+$work_dir
  end
  check_dir_exists($work_dir)
  if !$tmp_dir.match(/[A-z]/)
    $tmp_dir=$work_dir+"/tmp"
  end
  if $verbose_mode == 1
    puts "Information:\tSetting temporary directory to "+$work_dir
  end
  check_dir_exists($tmp_dir)
  os_name=%x["uname"]
  if !os_name.match(/SunOS/)
    $test_mode=1
  else
    os_ver=%x[uname -r]
    if os_ver.match(/5\.11/)
      $default_net="net0"
    end
  end
  if !$default_host.match(/[0-9]/)
    message="Determining:\tDefault host IP"
    command="ipadm show-addr #{$default_net}/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'"
    $default_host=execute_command(message,command)
    $default_host=$default_host.chomp
  end
  if !$default_apache_allow.match(/[0-9]/)
    $default_apache_allow=$default_host.split(/\./)[0..2].join(".")
  end
  if $verbose_mode == 1
    puts "Information:\tSetting apache allow range to "+$default_apache_allow
  end
  return
end

# Get command line arguments
# Print help if given none

if !ARGV[0]
  print_usage()
end

begin
  opt=Getopt::Std.getopts($options)
rescue
  print_usage()
end

# Print version

if opt["V"]
  print_version()
  exit
end

# Prient usage

if opt["h"]
  print_usage()
end

# Enable test mode

if opt["v"]
  $verbose_mode=1
  puts "Information:\tRunning in verbose mode"
end

# Enable verbose mode

if opt["t"]
  $test_mode=1
  puts "Information:\tRunning in test mode"
end

# Check local configuration

check_local_config()

if !opt["c"] and !opt["S"] and !opt["d"] and !opt["z"] and !opt["W"] and !opt["C"] and !opt["R"] and !opt["L"] and !opt["P"]
  puts "Warning:\tClient name not given"
  exit
else
  if opt["c"]
    client_name=opt["c"]
  end
  if opt["d"]
    client_name=opt["d"]
  end
  if opt["z"]
    service_name=opt["z"]
  end
  if opt["n"]
    service_name=opt["n"]
  end
  if opt["c"] or opt["d"]
    puts "Information:\tSetting client name to "+client_name
  end
  if opt["z"] or opt["n"]
    puts "Information:\tSetting service name to "+service_name
  end
end

# Get MAC address if given

if opt["c"]
  client_mac=opt["e"]
end

# Routines for Jumpstart (Solaris 10 and earlier)

if opt["J"]
  if opt["d"]
    client_name=opt["d"]
    delete_js_client(client_name)
  else
    if opt["S"]
      if opt["n"]
        service_name=opt["n"]
      end
    end
  end
end

# Setup some defaults

if opt["P"]
  publisher_port=opt["P"]
else
  publisher_port=$default_ai_port
end

if opt["H"]
  publisher_host=opt["H"]
else
  publisher_host=$default_host
end

if opt["e"]
  client_mac=opt["e"]
else
  client_mac=""
end

if opt["i"]
  client_ip=opt["i"]
else
  client_mac=""
end

if opt["n"]
  service_name=opt["n"]
  if !service_name.match(/^[A-z]/)
    puts "Warning:\tService name must start with letter"
  end
else
  if !opt["z"]
    service_name=""
  end
end

if opt["f"]
  iso_file=opt["f"]
else
  iso_file=""
end

if opt["a"]
  client_arch=opt["a"]
  client_arch=client_arch.downcase
else
  client_arch=""
end

if opt["Z"]
  $destroy_fs=1
end

if opt["R"]
  $use_alt_repo=1
end

if opt["D"]
  $use_defaults=1
  if $verbose_mode == 1
    puts "Information:\tSetting answers to defaults"
  end
end

if opt["l"]
  linux_distro=opt["l"]
else
  linux_distro=""
end

if opt["r"]
  linux_version=opt["r"]
else
  linux_version=""
end

# Routines for AI (Solaris 11)

if opt["A"]
  if opt["L"] and opt["S"]
    list_ai_services()
    exit
  end
  if opt["W"]
    if !opt["n"]
      puts "Warning:\tNo service name"
      exit
    else
      service_name=opt["n"]
      service_base_name=get_service_base_name(service_name)
    end
    add_apache_proxy(publisher_host,publisher_port,service_base_name)
    exit
  end
  if opt["z"]
    if !opt["R"]
      unconfigure_ai_service(service_name)
      exit
    end
  end
  if opt["d"]
    client_name=opt["d"]
    unconfigure_ai_client(client_name,service_name,client_mac)
  else
    if opt["L"] and opt["C"]
      list_ai_clients()
      exit
    end
    if !opt["S"] and !opt["C"] and !opt["R"]
      check_client_arch(client_arch)
    end
    if opt["S"] or opt["C"] or opt["R"]
      if opt["R"]
        if !opt["S"]
          if opt["z"]
            unconfigure_alt_pkg_repo(service_name)
          else
            configure_alt_pkg_repo(publisher_host,publisher_port,service_name)
          end
        end
      end
      if opt ["C"] or opt["S"]
        if !opt["C"]
          configure_ai_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
        end
        configure_ai_client_services(client_arch,publisher_host,publisher_port,service_name)
      end
    else
      if opt["c"]
        check_client_mac(client_mac)
        check_client_arch(client_arch)
        check_client_ip(client_ip)
        configure_ai_client(client_name,client_arch,client_mac,client_ip)
      end
    end
  end
end

# Routines for Kickstart (Linux)

if opt["K"]
  if opt["W"]
    if opt["z"]
      remove_apache_alias(service_name)
    else
      add_apache_alias(service_name)
    end
    exit
  end
  if opt["R"] and !opt["S"] and !opt["c"]
    check_ks_service_name(service_name)
    if opt["z"]
      unconfigure_alt_pkg_ks(service_name)
    else
      configure_alt_pkg_ks(service_name)
    end
    exit
  end
  if opt["S"]
    if opt["P"]
      if opt["z"]
        unconfigure_ks_pxeboot(service_name)
      else
        configure_ks_pxeboot(service_name)
      end
      exit
    end
    if opt['L']
      list_ks_services()
      exit
    end
    if opt["z"]
      unconfigure_ks_server(service_name)
    else
      check_linux_distro(linux_distro)
      configure_ks_server(linux_distro,linux_version)
    end
  else
    if opt['L']
      list_ks_clients()
      exit
    end
    if !opt["d"]
      check_client_mac(client_mac)
      check_client_ip(client_ip)
      check_ks_service_name(service_name)
    end
    if opt["P"]
      if opt["d"]
        un_configure_ks_client_pxeboot(client_name)
        un_configure_ks_client_dhcp(client_name)
      else
        configure_ks_client_pxeboot(client_name,client_mac,service_name)
        configure_ks_client_dhcp(client_name,client_mac,client_ip)
      end
      exit
    end
    if opt["z"]
      unconfigure_ks_client(client_name)
    else
      configure_ks_client(client_name,client_mac,client_ip,service_name)
    end
  end
end
