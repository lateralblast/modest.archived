
# AI Package routines

# Populate package information

def populate_ai_pkg_info()
  p_struct={}

  name="puppet"
  config=Pkg.new(
    info      = "Puppet is IT automation software that helps system administrators manage infrastructure throughout its lifecycle, from provisioning and configuration to orchestration and reporting.",
    type      = "ruby",
    version   = "3.4.0",
    depend    = "depend fmri=pkg://#{$alt_prefix_name}/application/facter type=require,depend fmri=pkg://#{$alt_prefix_name}/application/hiera type=require",
    base_url  = "http://downloads.puppetlabs.com/#{name}"
    )
  p_struct[name]=config

  name="hiera"
  config=Pkg.new(
    info      = "A simple pluggable Hierarchical Database.",
    type      = "ruby",
    version   = "1.3.0",
    depend    = "",
    base_url  = "http://downloads.puppetlabs.com/#{name}"
    )
  p_struct[name]=config

  name="facter"
  config=Pkg.new(
    info      = "Facter is an independent, cross-platform Ruby library designed to gather information on all the nodes you will be managing with Puppet.",
    type      = "ruby",
    version   = "1.7.4",
    depend    = "",
    base_url  = "http://downloads.puppetlabs.com/#{name}"
    )
  p_struct[name]=config

  return p_struct
end

# Create mog file

def create_ai_mog_file(p_struct,pkg_name,spool_dir)
  pkg_info=p_struct[pkg_name].info
  pkg_depend=p_struct[pkg_name].depend
  pkg_version=p_struct[pkg_name].version
  pkg_arch=%x[uname -p]
  pkg_arch=pkg_arch.chomp
  mog_file=spool_dir+"/"+pkg_name+".mog"
  text=[]
  depend_list=[]
  text.push("set name=pkg.fmri value=application/#{pkg_name}@#{pkg_version},1.0")
  text.push("set name=pkg.description value=\"#{pkg_info}\"")
  text.push("set name=pkg.summary value=\"#{pkg_name} #{pkg_version}\"")
  text.push("set name=variant.arch value=#{pkg_arch}")
  text.push("set name=info.classification value=\"org.opensolaris.category.2008:Applications/System Utilities\"")
  if pkg_depend.match(/[A-z]/)
    if pkg_depend.match(/,/)
      depend_list=pkg_depend.split(/,/)
    else
      depend_list[0]=pkg_depend
    end
    depend_list.each do |temp_depend|
      text.push(temp_depend)
    end
  end
  File.open(mog_file,"w") {|file| file.puts text}
  return mog_file
end

# Create IPS package

def create_ai_ips_pkg(pkg_name,pkg_arch,spool_dir,install_dir,mog_file)
  manifest_file=spool_dir+"/"+pkg_name+".p5m"
  temp_file_1=spool_dir+"/"+pkg_name+".p5m.1"
  temp_file_2=spool_dir+"/"+pkg_name+".p5m.2"
  commands=[]
  commands.push("cd #{install_dir} ; pkgsend generate . |pkgfmt > #{temp_file_1}")
  commands.push("cd #{install_dir} ; pkgmogrify -DARCH=#{pkg_arch} #{temp_file_1} #{mog_file} |pkgfmt > #{temp_file_2}")
  commands.push("cd #{install_dir} ; pkgdepend generate -md . #{temp_file_2} |pkgfmt |sed 's/path=usr owner=root group=bin/path=usr owner=root group=sys/g' |sed 's/path=etc owner=root group=bin/path=usr owner=root group=sys/g' > #{manifest_file}")
  commands.push("cd #{install_dir} ; pkgdepend resolve -m #{manifest_file}")
  commands.each do |command|
    message=""
    execute_command(message,command)
  end
  return
end

# Publish IPS package

def publish_ai_ips_pkg(pkg_name,spool_dir,install_dir,pkg_repo_dir)
  message="Publishing: Package "+pkg_name+" to "+pkg_repo_dir
  command="cd #{install_dir} ; pkgsend publish -s #{pkg_repo_dir} -d . #{spool_dir}/#{pkg_name}.p5m.res"
  execute_command(message,command)
  return
end

# Build package

def build_ai_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
  pkg_version=p_struct[pkg_name].version
  repo_pkg_version=check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
  if !repo_pkg_version.match(/#{pkg_version}/)
    source_dir=$repo_base_dir+"/source"
    check_zfs_fs_exists(source_dir)
    pkg_version=p_struct[pkg_name].version
    source_name=pkg_name+"-"+pkg_version+".tar.gz"
    source_file=source_dir+"/"+source_name
    source_base_url=p_struct[pkg_name].base_url
    source_url=source_base_url+"/"+source_name
    if !File.exists?(source_file)
      get_pkg_source(source_url,source_file)
    end
    build_dir=$work_dir+"/build"
    check_dir_exists(build_dir)
    install_dir=build_dir+"/install"
    extract_dir=build_dir+"/source"
    spool_dir=build_dir+"/spool"
    dir_list=[install_dir,extract_dir,spool_dir]
    dir_list.each do |dir_name|
      if File.directory?(dir_name)
        message="Cleaning:\tDirectory "+dir_name
        command="cd #{dir_name} ; rm -rf *"
        execute_command(message,command)
      end
      check_dir_exists(dir_name)
    end
    message="Extracting:\tSource "+source_file+" to "+extract_dir
    command="cd #{extract_dir} ; gcat #{source_file} |tar -xpf -"
    execute_command(message,command)
    compile_dir=extract_dir+"/"+pkg_name+"-"+pkg_version
    if p_struct[pkg_name].type == "ruby"
      message="Compling:\t"+pkg_name
      command="cd #{compile_dir} ; ./install.rb --destdir=#{install_dir} --full"
      execute_command(message,command)
    end
    if build_type == "ips"
      mog_file=create_mog_file(p_struct,pkg_name,spool_dir)
      client_arch=%x[uname -p]
      client_arch=client_arch.chomp()
      create_ai_ips_pkg(pkg_name,client_arch,spool_dir,install_dir,mog_file)
      publish_ai_ips_pkg(pkg_name,spool_dir,install_dir,pkg_repo_dir)
    end
  end
  return
end

# Check a package is in the repository

def check_ai_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
  pkg_version=p_struct[pkg_name].version
  message="Checking:\tIf repository contains "+pkg_name+" "+pkg_version
  command="pkg info -g #{pkg_repo_dir} -r #{pkg_name} |grep Version |awk '{print $2}'"
  output=execute_command(message,command)
  repo_pkg_version=output.chomp
  return repo_pkg_version
end

# Build the alternate package repository so we can publish into it

def create_ai_alt_repo(pkg_repo_dir)
  if !File.exists?("#{pkg_repo_dir}/pkg5.repository")
    check_zfs_fs_exists(pkg_repo_dir)
    message="Creating:\tAlternate package repository in "+pkg_repo_dir
    command="pkgrepo create #{pkg_repo_dir}"
    execute_command(message,command)
  else
    message="Rebuilding:\tAlternate package repository in "+pkg_repo_dir
    command="pkgrepo rebuild -s #{pkg_repo_dir}"
    execute_command(message,command)
  end
  message="Setting:\tAlternate pacakge repository prefix to "+$alt_prefix_name
  command="pkgrepo set -s #{pkg_repo_dir} publisher/prefix=#{$alt_prefix_name}"
  execute_command(message,command)
  return
end

# Unconfigure the alternate package repository

def unconfigure_ai_alt_repo(service_name)
  p_struct=populate_pkg_info()
  p_struct.each do |pkg_name, value|
    p_struct.each do |temp_pkg_name, temp_value|
      pkg_depend=p_struct[temp_pkg_name].depend
      if pkg_depend.match(/#{pkg_name}/)
        uninstall_pkg(temp_pkg_name)
      end
    end
    uninstall_pkg(pkg_name)
  end
  alt_service_name=check_alt_service_name(service_name)
  pkg_repo_dir=$repo_base_dir+"/"+alt_service_name
  destroy_zfs_fs(pkg_repo_dir)
  alt_service_name=check_alt_service_name(service_name)
  unconfigure_ai_pkg_repo(alt_service_name)
  return
end

# Create a local repository for packages not in the Oracle Solaris repository
# This service instance is used for service out packages like puppet to clients

def configure_ai_alt_repo(publisher_host,publisher_port,service_name,client_arch)
  build_type="ips"
  read_only="false"
  alt_service_name=check_alt_service_name(service_name)
  pkg_repo_dir=$repo_base_dir+"/"+alt_service_name
  create_ai_alt_repo(pkg_repo_dir)
  publisher_port=publisher_port.to_i+1
  publisher_port=publisher_port.to_s
  configure_ai_pkg_repo(publisher_host,publisher_port,alt_service_name,pkg_repo_dir,read_only)
  p_struct=populate_pkg_info()
  process_ai_pkgs(p_struct,pkg_repo_dir,build_type)
  return
end
