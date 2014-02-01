
# Common code to all Jumpstart functions

# Question/config structure

Js=Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# UFS filesystems

Fs=Struct.new(:name, :mount, :slice, :mirror, :size)

def populate_js_fs_list()

  f_struct = {}
  f_order  = []

  name = "root"
  config = Fs.new(
    name      = "root",
    mount     = "/",
    slice     = "0",
    mirror    = "d10",
    size      = "8192"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "swap"
  config = Fs.new(
    name      = "swap",
    mount     = "/",
    slice     = "1",
    mirror    = "d20",
    size      = "8192"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "var"
  config = Fs.new(
    name      = "var",
    mount     = "/var",
    slice     = "3",
    mirror    = "d30",
    size      = "8192"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "opt"
  config = Fs.new(
    name      = "opt",
    mount     = "/opt",
    slice     = "4",
    mirror    = "d40",
    size      = "4096"
    )
  f_struct[name] = config
  f_order.push(name)

  name = "export"
  config = Fs.new(
    name      = "export",
    mount     = "/home/home",
    slice     = "5",
    mirror    = "d50",
    size      = "free"
    )
  f_struct[name] = config
  f_order.push(name)

  return f_struct,f_order
end

# Get ISO/repo version info

def get_js_iso_version(base_dir)
  message = "Checking:\tSolaris Version"
  command = "ls #{base_dir} |grep Solaris"
  output  = execute_command(message,command)
  iso_version = output.chomp
  iso_version = iso_version.split(/_/)[1]
  return iso_version
end

# Get ISO/repo update info

def get_js_iso_update(base_dir,os_version)
  release_file = base_dir+"/Solaris_"+os_version+"/Product/SUNWsolnm/reloc/etc/release"
  message = "Checking:\tSolaris release"
  command = "cat #{release_file} |head -1 |awk '{print $4}'"
  output  = execute_command(message,command)
  case output
  when /1\/06/
    iso_update = "1"
  when /6\/06/
    iso_update = "2"
  when /11\/06/
    iso_update = "3"
  when /8\/07/
    iso_update = "4"
  when /5\/08/
    iso_update = "5"
  when /10\/08/
    iso_update = "6"
  when /5\/09/
    iso_update = "7"
  when /10\/09/
    iso_update = "8"
  when /9\/10/
    iso_update = "9"
  when /8\/11/
    iso_update = "10"
  when /1\/13/
    iso_update = "11"
  end
  return iso_update
end
