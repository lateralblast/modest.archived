#!/usr/bin/env ruby

# Name:         modest (Muti OS Deployment Engine Server Tool)
# Version:      0.2.8
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
$options="F:a:c:d:e:f:i:n:z:ACJKSVWtv"
$verbose_mode=0
$test_mode=0
$iso_base_dir="/export/isos"
$repo_base_dir="/export/repo"
$iso_mount_dir="/cdrom"
$ai_base_dir="/export/auto_install"
$work_dir=""
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
$default_search="local"
$default_files="files"
$default_hosts="files dns"
$default_root_password="XXXX"
$default_admin_password="YYYY"

# Load methods

if File.directory?("./methods")
  file_list=Dir.entries("./methods")
  for file in file_list
    if file =~/rb$/
      require "./methods/#{file}"
    end
  end
end

# Handle SMF service

def handle_smf_service(function,smf_service_name)
  uc_function=function.capitalize
  message=uc_function+":\tService "+smf_service_name
  command="svcadm #{function} #{smf_service_name} ; sleep 5"
  output=execute_command(message,command)
  return output
end

# Disable SMF service

def disable_smf_service(smf_service_name)
  function="disable"
  handle_smf_service(function,smf_service_name)
end

# Enable SMF service

def enable_smf_service(smf_service_name)
  function="enable"
  handle_smf_service(function,smf_service_name)
end

# Refresh SMF service

def refresh_smf_service(smf_service_name)
  function="refresh"
  handle_smf_service(function,smf_service_name)
end

# Convert current date to a string that can be used in file names

def get_date_string()
  time=Time.new
  time=time.to_a
  date=Time.utc(*time)
  date_string=date.to_s.gsub(/\s+/,"_")
  date_string=date_string.gsub(/:/,"_")
  date_string=date_string.gsub(/-/,"_")
  if $verbose_mode == 1
    puts "Information:\tSetting date string to "+date_string
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  possible=[('a'..'z'),('A'..'Z'),(0..9),'.','/'].inject([]) {|s,r| s+Array(r)}
  salt=Array.new(8){possible[rand(possible.size)]}
  password=password.crypt("$1$#{salt}")
  return password
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
  puts ""
  puts "Examples:"
  puts ""
  puts "Delete AI service:\t\t"+$script+" -A -z sol_11_1"
  puts "Create all AI services:\t\t"+$script+" -A -S"
  puts "Configure AI client services:\t"+$script+" -A -C -a i386"
  puts "Create AI client:\t\t"+$script+" -A -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
  puts "Update AI proxy:\t\t"+$script+" -A -W -n sol_11_1"
  puts "Delete AI client:\t\t"+$script+" -A -d sol11u01vm03"
  puts ""
  exit
end

# Print script version information

def print_version()
  file_array=IO.readlines $0
  version=file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager=file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name=file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  puts name+" v. "+version+" "+packager
  exit
end

def get_client_mac(client_name)
  ethers_file="/etc/ethers"
  if File.exists?(ethers_file)
    message="Checking:\tFile "+ethers_file+" for "+client_name+" MAC address"
    command="cat #{ethers_file} |grep '#{client_name} '|awk '{print $2}'"
    output=execute_command(message,command)
  end
  return output
end

# Check if a directory exists
# If not create it

def check_dir_exists(dir_name)
  output=""
  if !File.directory?(dir_name)
    message="Creating:\t"+dir_name
    command="mkdir #{dir_name}"
    output=execute_command(message,command)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(dir_name)
  output=""
  if !File.directory?(dir_name)
    message="Warning:\t"+dir_name+" does not exist"
    command="zfs create #{$default_zpool}#{dir_name}"
    output=execute_command(message,command)
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(message,command)
  output=""
  if $verbose_mode == 1
    if message.match(/[A-z|0-9]/)
      puts message
    end
    puts "Executing:\t"+command
  end
  if $test_mode == 1
    if !command.match(/create|update|import|delete|svccfg|rsync|cp|touch|svcadm/)
      output=%x[#{command}]
    end
  else
    output=%x[#{command}]
  end
  if $verbose_mode == 1
    if output.length > 1
      if output.match(/\n/)
        puts "Output:\t\t"+output
      else
        output=output.split(/\n/)
        output.each do |line|
          puts "Output:\t\t"+line
        end
      end
    end
  end
  return output
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
  puts "Setting:\tWork directory to "+$work_dir
  if !File.directory?($work_dir)
    message="Creating:\t"+$work_dir
    command="mkdir #{$work_dir}"
    execute_command(message,command)
  end
  os_name=%x["uname"]
  if !os_name.match(/SunOS/)
    $test_mode=1
  else
    os_ver=%x[uname -r]
    if os_ver.match(/5\.11/)
      $default_net="net0"
    end
  end
  message="Determining:\tDefault host IP"
  command="ipadm show-addr #{$default_net}/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'"
  $default_host=execute_command(message,command)
  $default_host=$default_host.chomp
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

if !opt["c"] and !opt["S"] and !opt["d"] and !opt["z"] and !opt["W"] and !opt["C"]
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
  if opt["c"] or opt["d"]
    puts "Information:\tSetting client name to "+client_name
  end
  if opt["z"]
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
if opt["n"]
  service_name=opt["n"]
else
  service_name=""
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
  service_name=""
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

# Routines for AI (Solaris 11)

if opt["A"]
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
    service_name=opt["z"]
    delete_ai_service(service_name)
    exit
  end
  if opt["d"]
    client_name=opt["d"]
    delete_ai_client(client_name,service_name,client_mac)
  else
    if !opt["a"]
      if !opt["S"] and !opt["C"]
        puts "Warning:\tArchitecture not specified"
        puts "Warning:\tUse -a i386 or -a sparc"
        exit
      end
    end
    if opt["S"] or opt["C"]
      if !opt["C"]
        configure_ai_server(client_arch,publisher_host,publisher_port,service_name,iso_file)
      end
      configure_ai_client_services(client_arch,publisher_host,publisher_port,service_name)
    else
      if !opt["e"]
        puts "Warning:\tNo client MAC address given"
        exit
      end
      if !client_arch.match(/i386|sparc/)
        puts "Warning:\tInvalid architecture specified"
        puts "Warning:\tUse -a i386 or -a sparc"
        exit
      end
      if !opt["i"]
        puts "Warning:\tNo client IP address given"
        exit
      end
      configure_ai_client(client_name,client_arch,client_mac,client_ip)
    end
  end
end

