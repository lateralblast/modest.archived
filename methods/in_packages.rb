
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

def populate_puppet_rpm_list(service_name,client_arch)
  release_dir     = service_name.split(/_/)[1]
  puppet_base_dir = $pkg_base_dir+"/puppet"
  rpm_list = %x[cd #{puppet_base_dir} ; find . -name "*.rpm" |grep 'el/#{release_dir}' |grep '#{client_arch}'].split("\n")
  return rpm_list
end
