
# Common routines for packages

# Create struct for package information

Pkg=Struct.new(:info, :type, :version, :depend, :base_url)

# Code to fetch a source file

def get_pkg_source(source_url,source_file)
  if !File.exists?("/usr/bin/wget")
    message = "Installing:\tPackage wget"
    command = "pkg install pkg:/web/wget"
    execute_command(message,command)
  end
  message = "Fetching:\tSource "+source_url+" to "+source_file
  command = "wget #{source_url} -O #{source_file}"
  execute_command(message,command)
  return
end

# Check installed packages

def check_installed_pkg(p_struct,pkg_name)
  message           = "Checking:\tIf package "+pkg_name+" is installed"
  command           = "pkg info #{pkg_name} |grep Version |awk '{print $2}'"
  installed_version = execute_command(message,command)
  installed_version = installed_version.chomp
  return installed_version
end

# Install a package

def install_pkg(p_struct,pkg_name,pkg_repo_dir)
  pkg_version       = p_struct[pkg_name].version
  installed_version = check_installed_pkg(p_struct,pkg_name)
  if !installed_version.match(/#{pkg_version}/)
    message = "Installing:\tPackage "+pkg_name
    command = "pkg install -g #{pkg_repo_dir} #{pkg_name}"
    execute_command(message,command)
  end
  return
end

# Handle a package

def handle_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
  if $verbose_mode == 1
    puts "Handling:\tPackage "+pkg_name
  end
  depend_list     = []
  pkg_version     = p_struct[pkg_name].version
  temp_pkg_name = p_struct[pkg_name].depend
  if tempt_pkg_name.match(/[A-z]/)
    if temp_pkg_name.match(/,/)
      depend_list = temp_pkg_name.split(/,/)
    else
      depend_list[0] = temp_pkg_name
    end
    depend_list.each do |depend_pkg_name|
      if depend_pkg_name.match(/\//)
          depend_pkg_name = depend_pkg_name.split(/\//)[-1]
        if depend_pkg_name.match(/\ = /)
          depend_pkg_name = depend_pkg_name.split(/ /)[0]
        end
      end
      if !depend_pkg_name.match(/#{pkg_name}/)
        if $verbose_mode == 1
          puts "Handling:\tDependency "+depend_pkg_name
        end
        build_pkg(p_struct,depend_pkg_name,build_type,pkg_repo_dir)
        install_pkg(p_struct,depend_pkg_name,pkg_repo_dir)
      end
    end
    repo_pkg_version = check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
    if !repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
      install_pkg(p_struct,pkg_name,pkg_repo_dir)
    end
  else
    repo_pkg_version = check_pkg_repo(p_struct,pkg_name,pkg_repo_dir)
    if !repo_pkg_version.match(/#{pkg_version}/)
      build_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
      install_pkg(p_struct,pkg_name,pkg_repo_dir)
    end
  end
  return
end

# Process package list

def process_pkgs(p_struct,pkg_repo_dir,build_type)
  p_struct.each do |pkg_name, value|
    handle_pkg(p_struct,pkg_name,build_type,pkg_repo_dir)
  end
  return
end

# Get the alternate repository name

def check_alt_service_name(service_name)
  if !service_name.match(/[A-z]/)
    client_arch       = %x[uname -p]
    client_arch       = client_arch.chomp()
    service_name      = get_service_name(client_arch)
    service_base_name = get_service_base_name(service_name)
    alt_service_name  = service_base_name+"_"+$alt_repo_name
  else
    alt_service_name = service_name
  end
  return alt_service_name
end

# Uninstall package

def uninstall_pkg(pkg_name)
  message = "Checking:\tIf package "+pkg_name+" is installed"
  command = "pkg info #{pkg_name} |grep Version |awk '{print $2}'"
  output  = execute_command(message,command)
  if output.match(/[0-9]/)
    message = "Uninstalling:\tPackage "+pkg_name
    command = "pkg uninstall #{pkg_name}"
    output  = execute_command(message,command)
  end
  return
end

# RPM list

def populate_puppet_rpm_list(service_name,client_arch)
  pkg_list = {}
  rpm_list = []
  pkg_list["facter"] = $facter_version
  pkg_list["hiera"]  = $hiera_version
  pkg_list["puppet"] = $puppet_version
  pkg_list.each do |key, value|
    if service_name.match(/centos_5|rhel_5|sl_5|oel_5/)
      puppet_url = "https://yum.puppetlabs.com"
      puppet_url = puppet_url+"/el/5/products/"+client_arch
      if key.match(/facter/)
        rpm_url = puppet_url+"/"+key+"-"+value+"-1.el5."+client_arch+".rpm"
      else
        rpm_url = puppet_url+"/"+key+"-"+value+"-1.el5.noarch.rpm"
      end
    end
    if service_name.match(/centos_6|rhel_6|sl_6|oel_6/)
      puppet_url = puppet_url+"/el/6/products/"+client_arch+"/"
      if key.match(/facter/)
        rpm_url = puppet_url+"/"+key+"-"+value+"-1.el6."+client_arch+".rpm"
      else
        rpm_url = puppet_url+"/"+key+"-"+value+"-1.el6.noarch.rpm"
      end
    end
    rpm_list.push(rpm_url)
  end
  return rpm_list
end
