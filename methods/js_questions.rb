

# Jumpstart questions

# Get system architecture for sparc (sun4u/sun4v)

def get_js_system_karch(client_model)
  if client_model.downcase.match(/^t/)
    system_karch="sun4v"
  else
    system_karch="sun4u"
  end
  return system_karch
end

# Get disk id based on model

def get_js_nic_model()
  nic_model="e1000g0"
  case $q_struct["system_model"].value.downcase
  when /445|t1000/
    nic_model="bge0"
  when /280|440|480|490|4x0/
    nic_model="eri0"
  when /880|890|8x0/
    nic_model="ce0"
  when /250|450|220/
    nic_model="hme0"
  end
  return nic_model
end

# Get disk id based on model

def get_js_root_disk_id()
  root_disk_id="c0t0d0"
  case $q_struct["system_model"].value.downcase
  when /vmware/
    root_disk_id="any"
  when /445|440|480|490|4x0|880|890|8x0|t5220|t5120|t5xx0|t5140|t5240|t5440/
    root_disk_id="c1t0d0"
  when /100|120|x1/
    root_disk_id="c0t2d0"
  end
  return root_disk_id
end

# Get mirror disk id

def get_js_mirror_disk_id()
  root_disk_id=$q_struct["root_disk_id"].value
  mirror_controller_id=root_disk_id.split(/t/)[0].gsub(/^c/,"")
  mirror_target_id=root_disk_id.split(/t/)[1].split(/d/)[0]
  mirror_disk_id=root_disk_id.split(/d/)[1]
  system_model=$q_struct["system_model"].value.downcase
  case system_model
  when /^v8/
    mirror_target_id=Integer(mirror_target_id)+3
  when /^e6/
    mirror_controller_id=Integer(mirror_controller_id)+1
  else
    mirror_target_id=Integer(mirror_target_id)+1
  end
  mirror_disk_id="c"+mirror_controller_id+"t"+mirror_target_id+"d"+mirror_disk_id
  return mirror_disk_id
end

# Get disk size based on model

def get_js_disk_size()
  disk_size="73g"
  case $q_struct["system_model"].value.downcase
  when /vmware/
    disk_size="auto"
  when /t5220|t5120|t5xx0|t5140|t5240|t5440|t6300|t6xx0|t6320|t6340/
    disk_size="146g"
  when /280/
    disk_size="36g"
  end
  return disk_size
end

# Get disk size based on model

def get_js_memory_size()
  memory_size="1g"
  case $q_struct["system_model"].value.downcase
  when /280|250|450|220/
    memory_size="2g"
  when /100|120|x1|vmware/
    memory_size="1g"
  end
  return memory_size
end

# Set Jumpstart filesystem

def set_js_fs()
  if $q_struct["root_fs"].value.downcase.match(/zfs/)
    ["memory_size","disk_size","swap_size","root_metadb","mirror_metadb","metadb_size","metadb_count"].each do |key|
      $q_struct[key].ask="no"
      $q_struct[key].type=""
    end
    (f_struct,f_order)=populate_js_fs_list()
    f_order.each do |fs_name|
      key=fs_name+"_filesys"
      $q_struct[key].ask="no"
      $q_struct[key].type=""
      key=fs_name+"_size"
      $q_struct[key].ask="no"
      $q_struct[key].type=""
    end
  else
    $q_struct["zfs_layout"].ask="no"
    $q_struct["zfs_bootenv"].ask="no"
  end
  return $q_struct
end

# Get Jumpstart network information

def get_js_network()
  os_version=$q_struct["os_version"].value
  if Integer(os_version) > 7
    network="network_interface="+$q_struct["nic_model"].value+" { hostname="+$q_struct["hostname"].value+" default_route="+$q_struct["default_route"].value+" ip_address="+$q_struct["ip_address"].value+" netmask="+$q_struct["netmask"].value+" ipv6_protocol="+$q_struct["ipv6_protocol"].value+" }"
  else
    network="network_interface="+$q_struct["nic_model"].value+" { hostname="+$q_struct["hostname"].value+" default_route="+$q_struct["default_route"].value+" ip_address="+$q_struct["ip_address"].value+" netmask="+$q_struct["netmask"].value+" }"
  end
  return network
end

# Set install type

def set_js_install_type()
  if $q_struct["install_type"].value == "flash"
    $q_struct["install_cluster"].ask="no"
    $q_struct["install_cluster"].type=""
  else
    ["flash_location","flash_file","flash_host","flash_method"].each do |key|
      $q_struct[key].ask="no"
      $q_struct[key].type=""
    end
  end
  return $q_struct
end

# Set mirror disk

def set_js_mirror_disk()
  if $q_struct["mirror_disk"].value == "no"
    $q_struct["mirror_disk_id"].ask="no"
    $q_struct["mirror_disk_id"].type=""
  end
  return $q_struct
end

# Get Jumpstart flash location

def get_js_flash_location()
  flash_location=$q_struct["flash_method"].value+"://"+$q_struct["flash_host"].value+"/"+$q_struct["flash_file"].value
  return flash_location
end

# Get fs layout
def get_js_zfs_layout()
  if $q_struct["system_model"].value.match(/vmware/)
    $q_struct["swap_size"].value="auto"
  end
  if $q_struct["mirror_disk"].value == "yes"
    zfs_layout=$q_struct["rpool_name"].value+" "+$q_struct["disk_size"].value+" "+$q_struct["swap_size"].value+" "+$q_struct["dump_size"].value+" mirror "+$q_struct["root_disk_id"].value+" "+$q_struct["mirror_disk_id"].value
  else
    zfs_layout=$q_struct["rpool_name"].value+" "+$q_struct["disk_size"].value+" "+$q_struct["swap_size"].value+" "+$q_struct["dump_size"].value+" "+$q_struct["root_disk_id"].value
  end
  return zfs_layout
end

# Get ZFS bootenv

def get_js_zfs_bootenv(service_name)
  zfs_bootenv="installbe bename "+service_name
  return zfs_bootenv
end

# Get UFS filesys entries

def get_js_ufs_filesys(fs_mount,fs_slice,fs_mname,fs_psize)
  if $q_struct["mirror_disk"].value == "yes"
    filesys_entry=q_strut["root_disk_id"].value+fs_slice+" "+fs_psize+" "+fs_mount
  else
    filesys_entry="mirror:"+fs_mname+" "+$q_struct["root_disk_id"].value+fs_slice+" "+$q_struct["mirror_disk_id"].value+fs_slice+" "+fs_psize+" "+fs_mount
  end
  return filesys_entry
end

def get_js_filesys(fsname)
  (f_struct,f_order)=populate_js_fs_list()
  fs_mount=f_struct[fs_name].mount
  fs_slice=f_struct[fs_name].slice
  key_name=fs_name+"_size"
  fs_size=$q_struct[key_name].value
  fs_mirror=f_struct[fs_name].mirror
  filesys+get_js_ufs_filesys(fs_mount,fs_slice,fs_mname,fs_psize)
  return filesys_entry
end

# Get metadb entry

def get_js_metadb()
  meta_entry=$q_struct["root_disk_id"].value+"s7 size "+$q_struct["metadb_size"]+" count "+$q_struct["metadb_count"].size
  return metadb_entry
end

# Get root metadb entry

def get_js_root_metadb()
  meta_entry=$q_struct["root_disk_id"].value+"s7 size "+$q_struct["metadb_size"]+" count "+$q_struct["metadb_count"].size
  return metadb_entry
end

# Get mirror metadb entry

def get_js_mirror_metadb()
  meta_entry=$q_struct["mirror_disk_id"].value+"s7"
  return metadb_entry
end

# Get dump size

def get_js_dump_size()
  if $q_struct["system_model"].value.downcase.match(/vmware/)
    dump_size="auto"
  else
    dump_size=$q_struct["memory_size"].value
  end
  return dump_size
end

# Populate Jumpstart machine file

def populate_js_machine_questions(client_model,client_karch,publisher_host,service_name,os_version,os_update)
  $q_struct={}
  $q_order=[]

  # Store system model information from previous set of questions

  name="system_model"
  config=Js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = client_model,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config

  name="root_disk_id"
  config=Js.new(
    type      = "",
    question  = "System Disk",
    ask       = "yes",
    parameter = "",
    value     = "get_js_root_disk_id()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if client_model.downcase.match(/vmware/)
    mirror_disk="no"
  else
    mirror_disk="yes"
  end

  name="mirror_disk"
  config=Js.new(
    type      = "",
    question  = "Mirror Disk",
    ask       = "yes",
    parameter = "",
    value     = mirror_disk,
    valid     = "yes,no",
    eval      = "set_js_mirror_disk()"
    )
  $q_struct[name]=config
  $q_order.push(name)


  name="mirror_disk_id"
  config=Js.new(
    type      = "",
    question  = "System Disk",
    ask       = "yes",
    parameter = "",
    value     = "get_js_mirror_disk_id()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="system_karch"
  config=Js.new(
    type      = "",
    question  = "System Kernel Architecture",
    ask       = "yes",
    parameter = "",
    value     = client_karch,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config

  name="memory_size"
  config=Js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_memory_size()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="disk_size"
  config=Js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_disk_size()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="dump_size"
  config=Js.new(
    type      = "",
    question  = "System Dump Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_dump_size()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="install_type"
  config=Js.new(
    type      = "output",
    question  = "Install Type",
    ask       = "yes",
    parameter = "install_type",
    value     = $default_install,
    valid     = "",
    eval      = "set_js_install_type()"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="flash_method"
  config=Js.new(
    type      = "",
    question  = "Flash Restore Method",
    ask       = "yes",
    parameter = "",
    value     = "http",
    valid     = "nfs,http,ftp,file",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="flash_host"
  config=Js.new(
    type      = "",
    question  = "Flash Restore Server",
    ask       = "yes",
    parameter = "",
    value     = publisher_host,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  flash_file=

  name="flash_file"
  config=Js.new(
    type      = "",
    question  = "Flash File",
    ask       = "yes",
    parameter = "",
    value     = "",
    valid     = "",
    eval      = ""
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="flash_location"
  config=Js.new(
    type      = "output",
    question  = "Flash location",
    ask       = "yes",
    parameter = "flash_location",
    value     = "get_js_flash_location()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="cluster"
  config=Js.new(
    type      = "output",
    question  = "Install Cluser",
    ask       = "yes",
    parameter = "cluster",
    value     = "SUNWcall",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="disk_partitioning"
  config=Js.new(
    type      = "output",
    question  = "Disk Paritioning",
    ask       = "yes",
    parameter = "partitioning",
    value     = "explicit",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if os_version == "10"
    if Integer(os_update) >= 6

      name="root_fs"
      config=Js.new(
        type      = "",
        question  = "Root filesystem",
        ask       = "yes",
        parameter = "",
        value     = "zfs",
        valid     = "",
        eval      = "set_js_fs()"
        )
      $q_struct[name]=config
      $q_order.push(name)

      name="rpool_name"
      config=Js.new(
        type      = "",
        question  = "Root Pool Name",
        ask       = "yes",
        parameter = "",
        value     = "rpool",
        valid     = "",
        eval      = "no"
        )
      $q_struct[name]=config
      $q_order.push(name)

    end
  end

  name="zfs_layout"
  config=Js.new(
    type      = "output",
    question  = "ZFS File System Layout",
    ask       = "yes",
    parameter = "pool",
    value     = "get_js_zfs_layout()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  zfs_bootenv=get_js_zfs_bootenv(service_name)
  name="zfs_bootenv"
  config=Js.new(
    type      = "output",
    question  = "File System Layout",
    ask       = "yes",
    parameter = "bootenv",
    value     = zfs_bootenv,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  (f_struct,f_order)=populate_js_fs_list()

  f_order.each do |fs_name|

    name=f_struct[fs_name].name+"_size"
    config=Js.new(
      type      = "",
      question  = f_struct[fs_name].name.upcase+" Size",
      ask       = "yes",
      parameter = "",
      value     = f_struct[fs_name].size,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name]=config
    $q_order.push(name)

    funct_string="get_js_filesys(\""+fs_name+"\")"

    name=f_struct[fs_name].name+"_filesys"
    config=Js.new(
      type      = "output",
      question  = "UFS Root File System",
      ask       = "yes",
      parameter = "filesys",
      value     = funct_string,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name]=config
    $q_order.push(name)

  end

  name="metadb_size"
  config=Js.new(
    type      = "",
    question  = "Metadb Size",
    ask       = "yes",
    parameter = "",
    value     = "16384",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="metadb_count"
  config=Js.new(
    type      = "",
    question  = "Metadb Count",
    ask       = "yes",
    parameter = "",
    value     = "3",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="root_metadb"
  config=Js.new(
    type      = "output",
    question  = "Root Disk Metadb",
    ask       = "yes",
    parameter = "metadb",
    value     = "get_js_root_metadb()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="mirror_metadb"
  config=Js.new(
    type      = "output",
    question  = "Mirror Disk Metadb",
    ask       = "yes",
    parameter = "metadb",
    value     = "get_js_mirror_metadb()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  return $q_struct,$q_order
end

# Populate Jumpstart sysidcfg questions

def populate_js_sysid_questions(client_name,client_ip,client_arch,client_model,os_version,os_update)
  $q_struct={}
  $q_order=[]

  name="hostname"
  config=Js.new(
    type      = "",
    question  = "System Hostname",
    ask       = "yes",
    parameter = "",
    value     = client_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config

  name="os_version"
  config=Js.new(
    type      = "",
    question  = "OS Version",
    ask       = "yes",
    parameter = "",
    value     = os_version,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config

  name="os_update"
  config=Js.new(
    type      = "",
    question  = "OS Update",
    ask       = "yes",
    parameter = "",
    value     = os_version,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config

  name="ip_address"
  config=Js.new(
    type      = "",
    question  = "System IP",
    ask       = "yes",
    parameter = "",
    value     = client_ip,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="netmask"
  config=Js.new(
    type      = "",
    question  = "System Netmask",
    ask       = "yes",
    parameter = "",
    value     = $default_netmask,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  ipv4_default_route=get_ipv4_default_route(client_ip)

  name="system_model"
  config=Js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = client_model,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if client_arch.match(/sparc/)

    name="system_karch"
    config=Js.new(
      type      = "",
      question  = "System Kernel Architecture",
      ask       = "yes",
      parameter = "",
      value     = "get_js_system_karch()",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name]=config

  end

  name="nic_model"
  config=Js.new(
    type      = "",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "get_js_nic_model()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="default_route"
  config=Js.new(
    type      = "",
    question  = "Default Route",
    ask       = "yes",
    parameter = "",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if Integer(os_version) > 7

    name="ipv6_protocol"
    config=Js.new(
      type      = "",
      question  = "IPv6",
      ask       = "yes",
      parameter = "",
      value     = "no",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name]=config
    $q_order.push(name)

  end

  name="network_interface"
  config=Js.new(
    type      = "output",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "network_interface",
    value     = "get_js_network()",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="timezone"
  config=Js.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = $default_timezone,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="system_locale"
  config=Js.new(
    type      = "output",
    question  = "System Locale",
    ask       = "yes",
    parameter = "system_locale",
    value     = $default_system_locale,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="terminal"
  config=Js.new(
    type      = "output",
    question  = "Terminal Type",
    ask       = "yes",
    parameter = "terminal",
    value     = "sun-cmd",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="timeserver"
  config=Js.new(
    type      = "output",
    question  = "Timeserver",
    ask       = "yes",
    parameter = "timeserver",
    value     = "localhost",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  name="name_service"
  config=Js.new(
    type      = "output",
    question  = "Name Service",
    ask       = "yes",
    parameter = "name_service",
    value     = $default_name_service,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if os_version == "10"
    if Integer(os_update) >= 5

      name="nfs4_domain"
      config=Js.new(
        type      = "output",
        question  = "NFSv4 Domain",
        ask       = "yes",
        parameter = "nfsv4_domain",
        value     = $default_nfsv4_domain,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name]=config
      $q_order.push(name)

    end
  end

  name="security_policy"
  config=Js.new(
    type      = "output",
    question  = "Security",
    ask       = "yes",
    parameter = "security_policy",
    value     = $default_security,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name]=config
  $q_order.push(name)

  if os_version == "10"
    if Integer(os_update) >= 10

      name="auto_reg"
      config=Js.new(
        type      = "output",
        question  = "Auto Registration",
        ask       = "yes",
        parameter = "auto_reg",
        value     = $default_auto_reg,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name]=config
      $q_order.push(name)

    end
  end

  return $q_struct,$q_order
end
