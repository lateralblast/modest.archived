#!/usr/bin/env ruby -w

# Name:         modest (Muti OS Deployment Engine Server Tool)
# Version:      1.1.6
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
require 'socket'
require 'parseconfig'

# Set up some global variables/defaults

$script                 = $0
$options                = "a:b:c:d:e:f:g:h:i:m:n:o:p:r:s:z:ABCDEFGHIJKLMNOPRSTUVWXYZtvy"
$verbose_mode           = 0
$test_mode              = 0
$iso_base_dir           = "/export/isos"
$repo_base_dir          = "/export/repo"
$ldom_base_dir          = "/ldoms"
$zone_base_dir          = "/zones"
$iso_mount_dir          = "/cdrom"
$ai_base_dir            = "/export/auto_install"
$lxc_base_dir           = "/lxc"
$lxc_image_dir          = "/export/images"
$work_dir               = ""
$tmp_dir                = ""
$alt_repo_name          = "alt"
$alt_prefix_name        = "solaris"
$home_dir               = ENV["HOME"]
$dhcpd_file             = "/etc/inet/dhcpd4.conf"
$fusion_dir             = ""
$default_zpool          = "rpool"
$default_ai_port        = "10081"
$default_host           = ""
$default_nic            = ""
$default_net            = "net0"
$default_timezone       = "Australia/Victoria"
$default_terminal       = "sun"
$default_country        = "AU"
$default_timeserver     = "0."+$default_country.downcase+".pool.ntp.org"
$default_keymap         = "US-English"
$default_environment    = "en_US.UTF-8"
$default_language       = "en_US"
$default_system_locale  = "C"
$default_nameserver     = "8.8.8.8"
$default_name_service   = "none"
$default_security       = "none"
$default_netmask        = "255.255.255.0"
$default_domain         = "local"
$default_search         = "local"
$default_files          = "files"
$default_hosts          = "files dns"
$default_root_password  = "XXXX"
$default_admin_password = "YYYY"
$use_alt_repo           = 0
$destroy_fs             = 0
$use_defaults           = 0
$default_apache_allow   = ""
$default_admin_name      = "Sys Admin"
$default_admin_user     = "sysadmin"
$default_admin_group    = "wheel"
$default_admin_home     = "/home/"+$default_admin_user
$default_admin_shell    = "/bin/bash"
$default_admin_uid      = "200"
$default_admin_gid      = "200"
$preseed_admin_uid      = "1000"
$preseed_admin_gid      = "1000"
$tftp_dir               = "/etc/netboot"
$default_cluster        = "SUNWCprog"
$default_install        = "initial_install"
$default_nfs4_domain    = "dynamic"
$default_auto_reg       = "disable"
$q_struct               = {}
$q_order                = []
$text_install           = 1
$backup_dir             = ""
$rpm2cpio_url           = "http://svnweb.freebsd.org/ports/head/archivers/rpm2cpio/files/rpm2cpio?revision=259745&view=co"
$rpm2cpio_bin           = ""
$vbox_disk_type         = "ide"
$vm_disk_size           = "10G"
$vm_memory_size         = "1024"
$use_serial             = 0
$os_name                = ""
$yes_to_all             = 0
$default_cdom_mau       = "1"
$default_gdom_mau       = "1"
$default_cdom_vcpu      = "8"
$default_gdom_mem       = "4G"
$default_gdom_vcpu      = "8"
$default_gdom_mem       = "4G"
$default_gdom_size      = "10G"
$default_cdom_name      = "initial"
$default_dpool          = "dpool"
$default_gdom_vnet      = "vnet0"

# Declare some package versions

$facter_version = "1.7.4"
$hiera_version  = "1.3.0"
$puppet_version = "3.4.1"

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
  puts "-K: Configure Kickstart (CentOS and RedHat)"
  puts "-U: Configure Preseed (Ubuntu)"
  puts "-Y: Configure AutoYast (SuSE)"
  puts "-E: Configure VSphere"
  puts "-Z: Configure Zone"
  puts "-M: Maintenance mode"
  puts "-a: Architecture"
  puts "-e: Client MAC Address"
  puts "-i: Client IP Address"
  puts "-m: Client model (used for Jumpstart)"
  puts "-S: Configure server"
  puts "-C: Configure client services"
  puts "-O: Configure VirtualBox VM"
  puts "-F: Configure VMware Fusion VM"
  puts "-o: Specify OS type (used when creating VMs)"
  puts "-r: Specify OS release (used when creating VMs)"
  puts "-b: Boot VM"
  puts "-s: Boot VM"
  puts "-g: Halt VM"
  puts "-p: Puplisher server port number"
  puts "-h: Puplisher server Hostname/IP"
  puts "-t: Run it test mode (in client mode create files but don't import them)"
  puts "-v: Run in verbose mode"
  puts "-f: ISO file to use"
  puts "-d: Delete client"
  puts "-n: Set service name"
  puts "-z: Delete service name"
  puts "-M: Maintenance operations"
  puts "-P: Configure PXE"
  puts "-W: Update apache proxy entry for AI"
  puts "-R: Use alternate package repository (additional packages like puppet)"
  puts "-y: Override (destroy ZFS filesystem as part of uninstallation and delete clients)"
  puts "-D: Use default values for questions"
  puts "-T: Use text mode install"
  puts "-B: Use serial connectivity (emulated)"
  puts "-X: X Windows based install (default is text based)"
  puts "    or run VM in GUI mode (default is headless)"
  puts "-H: Provide detailed examples"
  puts
  exit
  return
end

def print_examples(examples)
  puts
  if examples.match(/iso/)
    puts "Information related examples:"
    puts
    puts "List Linux ISOs:\t\t"+$script+" -K -S -I"
    puts "List Solaris 10 ISOs:\t\t"+$script+" -J -S -I"
    puts "List Solaris 11 ISOs:\t\t"+$script+" -A -S -I"
    puts
  end
  if examples.match(/vbox/)
    puts "Creating VirtualBox VM examples:"
    puts
    puts "Create KS (Linux) VM:\t\t\t"+$script+" -K -O -c centos59vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create PS (Linux) VM:\t\t\t"+$script+" -U -O -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create AY (Linux) VM:\t\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create JS (Solaris 10) VM:\t\t"+$script+" -J -O -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -O -c sol11u01vm03 -a i386 -e 00:50:56:26:92:D8"
    puts "Create VS (ESXi) VM:\t\t\t"+$script+" -E -O -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -O -d centos59vm01"
    puts "Delete JS (Solaris 10) VM:\t\t"+$script+" -O -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -O -d sol11u01vm03"
    puts "Delete VS (ESXi) VM:\t\t\t"+$script+" -O -d vmware55vm01"
    puts
    puts "Managing VirtualBox VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -O -b centos59vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -O -b centos59vm01 -B"
    puts "Boot non headless Linux VM:\t\t"+$script+" -O -b centos59vm01 -X"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -O -s centos59vm01"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -O -c centos59vm01 -e 00:50:56:34:4E:7A"
    puts
  end
  if examples.match(/fusion/)
    puts "Creating VMware Fusion VM examples:"
    puts
    puts "Create KS (Linux) VM:\t\t\t"+$script+" -K -F -c centos59vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create PS (Linux) VM:\t\t\t"+$script+" -U -F -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create AY (Linux) VM:\t\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create JS (Solaris 10) VM:\t\t"+$script+" -J -F -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -F -c sol11u01vm03 -a i386 -e 00:50:56:26:92:D8"
    puts "Create VS (ESXi) VM:\t\t\t"+$script+" -E -F -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts "Create NT (Windows) VM:\t\t\t"+$script+" -N -F -c win2008r2vm01 -e 08:00:27:61:B7:AF"
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -F -d centos59vm01"
    puts "Delete JS (Solaris 10) VM:\t\t"+$script+" -F -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -F -d sol11u01vm03"
    puts "Delete VS (ESXi) VM:\t\t\t"+$script+" -F -d vmware55vm01"
    puts
    puts "Managing VMware Fusion VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -F -b centos59vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -F -b centos59vm01 -B"
    puts "Boot non headless Linux VM:\t\t"+$script+" -F -b centos59vm01 -X"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -F -s centos59vm01"
    puts "Boot Windows VM:\t\t\t"+$script+" -F -b win2008r2vm01 -X"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -F -c centos59vm01 -e 00:50:56:34:4E:7A"
    puts
  end
  if examples.match(/server/)
    puts "Server related examples:"
    puts
    puts "List AI services:\t\t"+$script+" -A -S -L"
    puts "List KS services:\t\t"+$script+" -K -S -L"
    puts "List AY services:\t\t"+$script+" -Y -S -L"
    puts "List PS services:\t\t"+$script+" -U -S -L"
    puts "List JS services:\t\t"+$script+" -J -S -L"
    puts "Configure all AI services:\t"+$script+" -A -S"
    puts "Configure KS services:\t\t"+$script+" -K -S"
    puts "Configure JS services:\t\t"+$script+" -J -S"
    puts "Unconfigure AI service:\t\t"+$script+" -A -S -z sol_11_1"
    puts "Unconfigure KS service:\t\t"+$script+" -K -S -z centos_5_9"
    puts "Unconfigure JS service:\t\t"+$script+" -J -S -z sol_10_11"
    puts
  end
  if examples.match(/maint/)
    puts "Maintenance related examples:"
    puts
    puts "Configure AI client services:\t"+$script+" -A -M -C -a i386"
    puts "Enable AI proxy:\t\t"+$script+" -A -M -W -n sol_11_1"
    puts "Disable AI proxy:\t\t"+$script+" -A -M -W -z sol_11_1"
    puts "Configure AI alternate repo:\t"+$script+" -A -M -R"
    puts "Unconfigure AI alternate repo:\t"+$script+" -A -M -R -z sol_11_1_alt"
    puts "Configure KS alternate repo:\t"+$script+" -K -M -R -n centos_5_9_x86_64"
    puts "Unconfigure KS alternate repo:\t"+$script+" -K -M -R -z centos_5_9_x86_64"
    puts "Enable KS alias:\t\t"+$script+" -K -M -W -n centos_5_9_x86_64"
    puts "Disable KS alias:\t\t"+$script+" -K -M -W -z centos_5_9_x86_64"
    puts "Import KS PXE files:\t\t"+$script+" -K -M -P -n centos_5_9_x86_64"
    puts "Delete KS PXE files:\t\t"+$script+" -K -M -P -z centos_5_9_x86_64"
    puts "Unconfigure KS client PXE:\t"+$script+" -K -M -P -d centos59vm01"
    puts
  end
  if examples.match(/zone/)
    puts "Solaris Zone related examples:"
    puts
    puts "List Zones:\t\t\t"+$script+" -Z -L"
    puts "Configure Zone:\t\t\t"+$script+" -Z -c sol11u01z01 -i 192.168.1.181"
    puts "Delete Zone:\t\t\t"+$script+" -Z -d sol11u01z01"
    puts "Boot Zone:\t\t\t"+$script+" -Z -b sol11u01z01"
    puts "Boot Zone and connect to console:\t"+$script+" -Z -b sol11u01z01 -B"
    puts "Halt Zone:\t\t\t"+$script+" -Z -s sol11u01z01"
    puts
  end
  if examples.match(/ldom/)
    puts "Oracle VM Server for SPARC related examples:"
    puts
    puts "Configure Control Domain:\t\t"+$script+" -O -S"
    puts "List Guest Domains:\t\t\t"+$script+" -O -L"
    puts "Configure Guest Domain:\t\t\t"+$script+" -O -c sol11u01gd01"
    puts
  end
  if examples.match(/lxc/)
    puts "Linux Container related examples:"
    puts
    puts "List Containerss:\t\t\t"+$script+" -Z -L"
    puts "Configure Standard Container:\t\t"+$script+" -Z -c ubuntu1310lx01 -i 192.168.1.206"
    puts
  end
  if examples.match(/client|ks/)
    puts "Kickstart related examples:"
    puts
    puts "List KS clients:\t\t"+$script+" -K -C -L"
    puts "Create KS client:\t\t"+$script+" -K -C -c centos59vm01 -e 00:50:56:34:4E:7A -a x86_64 -i 192.168.1.194 -n centos_5_9_x86_64"
    puts "Delete KS client:\t\t"+$script+" -K -C -d centos59vm01"
    puts "Configure KS client PXE:\t"+$script+" -K -P -c centos59vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_9_x86_64"
    puts
  end
  if examples.match(/client|ai/)
    puts "AI related examples:"
    puts
    puts "List AI clients:\t\t"+$script+" -A -C -L"
    puts "Create AI client:\t\t"+$script+" -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
    puts "Delete AI client:\t\t"+$script+" -A -C -d sol11u01vm03"
    puts
  end
  if examples.match(/client|ps/)
    puts "Preseed related examples:"
    puts
    puts "List PS clients:\t\t"+$script+" -U -C -L"
    puts "Create PS client:\t\t"+$script+" -U -C -c ubuntu1310vm01 -e 08:00:27:BA:34:7C -a x86_64 -i 192.168.1.196 -n ubuntu_13_10_x86_64"
    puts "Delete PS client:\t\t"+$script+" -K -C -d ubuntu1310vm01"
    puts
  end
  if examples.match(/client|js/)
    puts "Jumpstart related examples:"
    puts
    puts "List JS clients:\t\t"+$script+" -J -C -L"
    puts "Create JS client:\t\t"+$script+" -J -C -c sol10u11vm01 -e 00:0C:29:FA:0C:7F -a i386 -i 192.168.1.195 -n sol_10_11"
    puts "Delete JS client:\t\t"+$script+" -J -C -d sol10u11vm01"
    puts
  end
  if examples.match(/client|ay/)
    puts "AutoYast related examples:"
    puts
    puts "List AY clients:\t\t"+$script+" -Y -C -L"
    puts "Create AY client:\t\t"+$script+" -Y -C -c sles11sp2vm01 -e 08:00:27:BA:34:7D -a x86_64 -i 192.168.1.197 -n sles_11_2_x86_64"
    puts "Delete AY client:\t\t"+$script+" -J -C -d sles11sp2vm01"
    puts
  end
  if examples.match(/client|vs/)
    puts "AutoYast related examples:"
    puts
    puts "List VS clients:\t\t"+$script+" -E -C -L"
    puts "Create VS client:\t\t"+$script+" -E -C -c vmware55vm01 -e 08:00:27:61:B7:AD -i 192.168.1.195 -n vmware_5_5_0_x86_64"
    puts "Delete VS client:\t\t"+$script+" -E -C -d vmware55vm01"
    puts
  end
  exit
end

# Get version

def get_version()
  file_array=IO.readlines $0
  version  = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name     = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version,packager,name
end

# Print script version information

def print_version()
  (version,packager,name)=get_version()
  puts name+" v. "+version+" "+packager
  exit
end

def create_client_mac(client_mac)
  if !client_mac.match(/[0-9]/)
    client_mac = (1..6).map{"%0.2X"%rand(256)}.join(":")
    if $verbose_mode == 1
      puts "Information:\tGenerated MAC address "+client_mac
    end
  end
  return client_mac
end

# Check local configuration
# Create work directory if it doesn't exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config(mode)
  if $verbose_mode == 1
    puts "Information:\tHome directory "+$home_dir
  end
  $id=%x[/usr/bin/id -u]
  $id=Integer($id)
  if !$work_dir.match(/[A-z]/)
    dir_name=File.basename($script,".*")
    if $id == 0
      $work_dir = "/opt/"+dir_name
    else
      $work_dir = $home_dir+"/."+dir_name
    end
  end
  if $verbose_mode == 1
    puts "Information:\tSetting work directory to "+$work_dir
  end
  check_dir_exists($work_dir)
  if !$tmp_dir.match(/[A-z]/)
    $tmp_dir = $work_dir+"/tmp"
  end
  if $verbose_mode == 1
    puts "Information:\tSetting temporary directory to "+$work_dir
  end
  # Get OS name and set system settings appropriately
  check_dir_exists($tmp_dir)
  $os_name = %x[uname]
  $os_name = $os_name.chomp
  $os_arch = %x[uname -p]
  $os_arch = $os_arch.chomp
  $os_mach = %x[uname -m]
  $os_mach = $os_mach.chomp
  $os_rel  = %x[uname -r]
  $os_rel  = $os_rel.chomp
  if $os_name.match(/SunOS|Darwin/)
    $os_info = %x[uname -a]
    $os_info = $os_info.chomp
    if $os_rel.match(/5\.11/) and $os_name.match(/SunOS/)
      $default_net = "net0"
    end
  else
    $os_info = %x[lsb_release -i]
    $os_info = $os_info.chomp
  end
  if $os_info.match(/Ubuntu/)
    $lxc_base_dir = "/var/lib/lxc"
  end
  if !$default_host.match(/[0-9]/)
    message = "Determining:\tDefault host IP"
    if $os_name.match(/SunOS/)
      command = "ipadm show-addr #{$default_net}/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'"
    end
    if $os_name.match(/Darwin/)
      $default_net="en0"
      command = "ifconfig #{$default_net} |grep 'inet ' |awk '{print $2}'"
    end
    if $os_name.match(/Linux/)
      $default_net="eth0"
      command = "ifconfig #{$default_net} |grep 'inet ' |awk '{print $2}'"
    end
    $default_host = execute_command(message,command)
    $default_host = $default_host.chomp
    if $default_host.match(/inet/)
      $default_host = $default_host.gsub(/^\s+/,"").split(/\s+/)[1]
    end
  end
  if !$default_apache_allow.match(/[0-9]/)
    $default_apache_allow=$default_host.split(/\./)[0..2].join(".")
  end
  if mode == "server"
    if $verbose_mode == 1
      puts "Information:\tSetting apache allow range to "+$default_apache_allow
    end
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat|CentOS/)
        check_yum_tftpd()
        check_yum_dhcpd()
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcpd.conf"
      else
        check_apt_tftpd()
        check_apt_dhcpd()
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
      end
    end
    if $os_name.match(/Darwin/)
      check_osx_tftpd()
      check_osx_dhcpd()
      $tftp_dir   = "/private/tftpboot"
      $dhcpd_file = "/usr/local/etc/dhcpd.conf"
    end
  else
    if $verbose_mode == 1
      puts "Information:\tSetting apache allow range to "+$default_apache_allow
    end
    if $os_name.match(/Linux/)
      if $os_info.match(/RedHat|CentOS/)
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcpd.conf"
      else
        $tftp_dir   = "/tftpboot"
        $dhcpd_file = "/etc/dhcp/dhcpd.conf"
      end
    end
    if $os_name.match(/Darwin/)
      $tftp_dir   = "/private/tftpboot"
      $dhcpd_file = "/usr/local/etc/dhcpd.conf"
    end
  end
  # If runnning on OS X check we have brew installed
  if $os_name.match(/Darwn/)
    if !File.exists?("/usr/local/bin/brew")
      message = "Installing:\tBrew for OS X"
      command = "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\""
      execute_command(message,command)
    end
  end
  # Set location of VMware Fusion and VirtualBox VMs
  if $os_name.match(/Darwin/)
    $fusion_dir=$home_dir+"/Documents/Virtual Machines.localized"
    if !File.directory?($fusion_dir)
      $fusion_dir=$home_dir+"/Documents/Virtual Machines"
    end
  end
  $backup_dir = $work_dir+"/backup"
  check_dir_exists($backup_dir)
  bin_dir     = $work_dir+"/bin"
  check_dir_exists(bin_dir)
  $rpm2cpio_bin=bin_dir+"/rpm2cpio"
  if !File.exist?($rpm2cpio_bin)
    message = "Fetching:\tTool rpm2cpio"
    command = "wget '#{$rpm2cpio_url}' -O #{$rpm2cpio_bin} ; chown #{$id} #{$rpm2cpio_bin} ; chmod +x #{$rpm2cpio_bin}"
    execute_command(message,command)
    system("chmod +x #{$rpm2cpio_bin}")
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

# Print examples

if opt["H"]
  $os_name = %x[uname]
  $os_arch = %x[uname -p]
  if opt["M"]
    examples = "maint"
  end
  if opt["S"]
    examples = "server"
  end
  if opt["O"]
    if $os_arch.match(/sparc/)
      examples = "ldom"
    else
      examples = "vbox"
    end
  end
  if opt["F"]
    check_promic_mode()
    examples = "fusion"
  end
  if opt["C"]
    examples = "client"
  end
  if opt["V"]
    examples = "vbox"
  end
  if opt["I"]
    examples = "iso"
  end
  if opt["K"]
    examples = "ai"
  end
  if opt["K"]
    examples = "ks"
  end
  if opt["J"]
    examples = "js"
  end
  if opt["U"]
    examples = "ps"
  end
  if opt["E"]
    examples = "vs"
  end
  if opt["Z"]
    if $os_name.match(/SunOS/)
      examples = "zone"
    else
      examples = "lxc"
    end
  end
  if !examples
    print_usage
  else
    print_examples(examples)
  end
  exit
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

# If given -y assume yes to all questions

if opt["y"]
  $yes_to_all = 1
  $destroy_fs = 1
  if $verbose_mode == 1
     puts "Warning:\tDestroying ZFS filesystems"+client_arch
  end
end

# Enable test mode

if opt["v"]
  $verbose_mode = 1
  puts "Information:\tRunning in verbose mode"
end

# Enable verbose mode

if opt["t"]
  $test_mode = 1
  puts "Information:\tRunning in test mode"
end

# Get OS type

if opt["o"]
  client_os=opt["o"]
else
  client_os=""
end

# Check local configuration

if opt["S"] or opt["W"]
  mode="server"
else
  mode="client"
end
check_local_config(mode)

if !opt["c"] and !opt["S"] and !opt["d"] and !opt["z"] and !opt["W"] and !opt["C"] and !opt["R"] and !opt["L"] and !opt["P"] and !opt["O"] and !opt["F"] and !opt["Z"]
  puts "Warning:\tClient name not given"
  exit
else
  if opt["c"]
    client_name  = opt["c"]
  end
  if opt["d"]
    client_name  = opt["d"]
  end
  if opt["z"]
    service_name = opt["z"]
  end
  if opt["n"]
    service_name = opt["n"]
  end
  if opt["b"]
    client_name  = opt["b"]
  end
  if opt["s"]
    client_name  = opt["s"]
  end
  if opt["c"] or opt["d"] or opt["b"] or opt["s"]
    if $verbose_mode == 1
      puts "Information:\tSetting client name to "+client_name
    end
  end
  if opt["z"] or opt["n"]
    if $verbose_mode == 1
      puts "Information:\tSetting service name to "+service_name
    end
  end
end

# Get MAC address if given

if opt["e"]
  client_mac=opt["e"]
  if $verbose_mode == 1
     puts "Information:\tClient ethernet MAC address is "+client_mac
  end
else
  client_mac = ""
end

# Get/set X based installer

if opt["X"]
  $text_install=0
  if $verbose_mode == 1
    puts "Information:\tSetting install type to X based"
  end
else
  $text_install=1
  if $verbose_mode == 1
    puts "Information:\tSetting install type to text based"
  end
end

# Get/set publisher port

if opt["p"]
  publisher_port = opt["p"]
else
  publisher_port = $default_ai_port
end
if $verbose_mode == 1
   puts "Information:\tSetting publisher port to "+publisher_port
end

# Get/set publisher host

if opt["h"]
  publisher_host=opt["h"]
else
  publisher_host=$default_host
end
if $verbose_mode == 1
   puts "Information:\tSetting publisher host to "+publisher_port
end

# Get IP address if given

if opt["i"]
  client_ip=opt["i"]
  if $verbose_mode == 1
     puts "Information:\tClient IP address is "+client_ip
  end
else
  client_ip = ""
end

# Get/set service name

if opt["n"]
  service_name=opt["n"]
  if !service_name.match(/^[A-z]/)
    puts "Warning:\tService name must start with letter"
  end
else
  if !opt["z"]
    service_name = ""
  end
end

# Get ISO file if given

if opt["f"]
  if !opt["Z"]
    iso_file=opt["f"]
    if $verbose_mode == 1
      puts "Information:\tUsing ISO "+iso_file
    end
  else
    image_file=opt["f"]
    if $verbose_mode == 1
      puts "Information:\tUsing Image "+image_file
    end
  end
else
  if opt["Z"]
    image_file = ""
  else
    iso_file = ""
  end
end

# Get architecture if given

if opt["a"]
  client_arch = opt["a"]
  client_arch = client_arch.downcase
  if client_arch.match(/sun4u|sun4v/)
  client_arch = "sparc"
  end
  if $verbose_mode == 1
     puts "Information:\tSetting architecture to "+client_arch
  end
else
  client_arch = ""
end

# If given -R use alternate repos

if opt["R"]
  $use_alt_repo = 1
else
  $use_alt_repo  = 0
end

# If given -D choose defaults for questions

if opt["D"]
  $use_defaults = 1
  if $verbose_mode == 1
    puts "Information:\tSetting answers to defaults"
  end
end

# If give a -T use text base install

if opt["T"]
  $text_install = 1
end

# If given -B use serial based install

if opt["B"]
  $text_install = 1
  $use_serial   = 1
  if $verbose_mode == 1
    puts "Information:\tUse serial connectivity"
  end
end

# Get/set system model

if opt["m"]
  if !opt["O"] and !$os_name.match(/sparc/)
    client_model = opt["m"]
    client_model = client_model.downcase
  end
else
  if !opt["S"]
    if opt["J"] and !opt["L"] and !opt["d"]
      if client_arch.match(/i386|x86|x86_64|x64/)
        puts "Warning:\tNo client architecture specified"
        puts "Setting:\tClient model to vmware"
        client_model = "vmware"
      else
        puts "Warning:\tClient model not specified"
        exit
      end
    else
      client_model = ""
    end
  end
end

# If given option O or F do VM related functions

if opt["O"]
  if $os_arch.match(/i386/)
    $vm_disk_size=$vm_disk_size.gsub(/G/,"000")
    vfunct = "vbox"
  else
    if opt["S"]
      vfunct = "cdom"
    else
      vfunct = "gdom"
    end
  end
end

if opt["F"]
  vfunct = "fusion"
end

# VirtualBox and VMware Fusion functions (not create)

if opt["O"] or opt["F"] and !opt["A"] and !opt["K"] and !opt["J"] and !opt["N"] and !opt["Y"] and !opt["U"] and !$os_arch.match(/sparc/)
  if opt ["L"]
    search_string = ""
    if opt["c"]
      search_string = opt["c"]
    end
    if opt["e"]
      search_string = opt["e"]
    end
    eval"[list_#{vfunct}_vms(search_string)]"
  end
  if opt["b"]
    client_name = opt["b"]
    eval"[boot_#{vfunct}_vm(client_name)]"
    exit
  end
  if opt["s"]
    client_name = opt["s"]
    eval"[stop_#{vfunct}_vm(client_name)]"
    exit
  end
  if opt["d"]
    eval"[unconfigure_#{vfunct}_vm(client_name)]"
  end
  if opt["e"]
    client_mac = opt["e"]
    eval"[change_#{vfunct}_vm_mac(client_name,client_mac)]"
  end
  exit
end

# Force architecture to 64 bit for ESX

if opt["E"]
  client_arch="x86_64"
  if $verbose_mode == 1
    puts "Setting:\tArchitecture to "+client_arch
  end
end

# If given -r set OS release

if opt["r"]
  client_rel = opt["r"]
  if $verbose_mode == 1
    puts "Setting:\tSolaris version of zone to "+client_rel
  end
else
  if $verbose_mode == 1
    client_rel = $os_rel
    puts "Setting:\tSolaris version of zone to same as host ["+$os_rel+"]"
  end
end

# If given -Z (Zones) make sure we are running on Solaris
# If given -O (LDoms) make sure we are on T series

if opt["Z"]
  if !$os_name.match(/SunOS|Linux/)
    puts "Warning:\tContainers can only be created on Solaris (Zones) or Linux (LXC)"
    exit
  else
    if $os_name.match(/SunOS/)
      vfunct = "zone"
      if opt["r"]
        if client_rel.match(/11/) and $client_rel.match(/10/)
          puts "Warning:\tCannot create Solaris 11 Zones on Solaris 10"
          exit
        end
      end
    else
      vfunct = "lxc"
    end
  end
end

# Handle Zones/Containers and LDoms

if opt["Z"] or opt["O"] and !opt["S"]
  if opt["O"] and !$os_mach.match(/sun4v/)
    puts "Warning:\tArchitecture does not support LDoms"
    exit
  end
  if opt["c"]
    eval"[configure_#{vfunct}(client_name,client_ip,client_mac,client_arch,client_os,client_rel,publisher_host,image_file,service_name)]"
  end
  if opt["L"]
    eval"[list_#{vfunct}s()]"
  end
  if opt["b"]
    client_name = opt["b"]
    eval"[boot_#{vfunct}(client_name)]"
  end
  if opt["s"]
    client_name = opt["s"]
    eval"[stop_#{vfunct}(client_name)]"
  end
  if opt["g"]
    client_name = opt["g"]
    eval"[halt_#{vfunct}(client_name)]"
    exit
  end
  if opt["d"]
    eval"[unconfigure_#{vfunct}(client_name)]"
  end
  exit
end

# Handle AI, Jumpstart, Kickstart/Preseed, ESXi, and PE

if opt["A"] or opt["K"] or opt["J"] or opt["E"] or opt["N"] or opt["U"] or opt["Y"] or opt["S"] or opt["Z"]
  # Set function
  if opt["A"]
    funct = "ai"
  end
  if opt["K"]
    funct = "ks"
  end
  if opt["Y"]
    funct = "ay"
  end
  if opt["U"]
    funct = "ps"
  end
  if opt["J"]
    funct = "js"
  end
  if opt["E"]
    funct = "vs"
  end
  if opt["N"]
    funct = "pe"
  end
  if opt["Z"]
    if $os_name.match(/SunOS/)
      funct = "zone"
    else
      funct = "lxc"
    end
  end
  if opt["O"] or opt["F"] and !$os_arch.match(/sparc/)
    if opt["c"]
      check_client_arch(client_arch)
      client_mac = create_client_mac(client_mac)
      eval"[configure_#{funct}_#{vfunct}_vm(client_name,client_mac,client_arch,client_os,client_rel)]"
    end
    if opt["L"]
      eval"[list_#{funct}_#{vfunct}_vms()]"
    end
    exit
  end
  # Handle server related functions
  if opt ["S"]
    if opt["O"] and $os_arch.match(/sparc/)
      configure_cdom(publisher_host)
      exit
    end
    check_dhcpd_config(publisher_host)
    check_apache_config()
    # List server services
    if opt["L"]
      eval"[list_#{funct}_services()]"
      exit
    end
    # List available ISOs
    if opt["I"]
      eval"[list_#{funct}_isos()]"
      exit
    end
    # Unconfigure server services
    if opt["z"]
      eval"[unconfigure_#{funct}_server(service_name)]"
      exit
    end
    eval"[configure_#{funct}_server(client_arch,publisher_host,publisher_port,service_name,iso_file)]"
    exit
  end
  # Perform maintenance related functions
  if opt["M"]
    # Handle PXE services
    if opt["P"]
      if opt["d"]
        eval"[unconfigure_#{funct}_pxe_client(client_name)]"
      end
      if opt["z"]
        eval"[unconfigure_#{funct}_pxe_boot(service_name)]"
      end
      if opt["n"]
        eval"[configure_#{funct}_pxe_boot(service_name)]"
      end
      exit
    end
    # Handle NFS services
    if opt["N"]
      if opt["n"]
        eval"[configure_#{funct}_nfs_service(service_name,publisher_host)]"
      else
        eval"[unconfigure_#{funct}_nfs_service(service_name)]"
      end
      exit
    end
    # Handle web services
    if opt["W"]
      if opt["n"]
        eval"[add_#{funct}_apache_entry(service_name)]"
      else
        eval"[remove_#{funct}_apache_entry(service_name)]"
      end
      exit
    end
    if opt["C"]
      eval"[configure_#{funct}_client_services(client_arch,publisher_host,publisher_port,service_name)]"
      exit
    end
    # Handle alternate packages (non OS install related)
    if opt["R"]
      if opt["z"]
        eval"[unconfigure_#{funct}_alt_repo(service_name)]"
      else
        eval"[configure_#{funct}_alt_repo(publisher_host,publisher_port,service_name,client_arch)]"
      end
      exit
    end
  end
  # Perform client related functions
  if opt["C"]
    # List clients
    if opt["L"]
      eval"[list_#{funct}_clients()]"
      exit
    end
    # Unconfigure client
    if opt["d"]
      eval"[unconfigure_#{funct}_client(client_name,client_mac,service_name)]"
      exit
    end
    if opt["c"]
      if !opt["K"]
        check_client_arch(client_arch)
      end
      check_client_mac(client_mac)
      if !opt["K"]
        check_client_arch(client_arch)
      end
      check_client_ip(client_ip)
      eval"[configure_#{funct}_client(client_name,client_arch,client_mac,client_ip,client_model,publisher_host,service_name)]"
    end
  end
end
