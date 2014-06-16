# Common *BSD and other code (e.g. CoreOS)

# List ISOs

def list_other_isos(search_string)
  puts
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    (iso_distro,iso_version,iso_arch) = get_other_version_info(iso_file_name)
    puts "ISO file:\t"+iso_file_name
    puts "Distribution:\t"+iso_distro
    puts "Version:\t"+iso_version
    puts "Architecture:\t"+iso_arch
    service_name     = iso_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
    repo_version_dir = $repo_base_dir+"/"+service_name
    if File.directory?(repo_version_dir)
      puts "Service Name:\t"+service_name+" (exists)"
    else
      puts "Service Name:\t"+service_name
    end
    puts
  end
  return
end

# Get BSD version info from the ISO

def get_other_version_info(iso_file)
  if iso_file.match(/install/)
    iso_distro  = "OpenBSD"
    if !iso_file.match(/i386|x86_64|amd64/)
      iso_arch    = %x[strings #{iso_file} |head -2 |tail -1 |awk '{print $2}'].split(/\//)[1].chomp
      iso_version = File.basename(iso_file,".iso").gsub(/install/,"").split(//).join(".")
    else
      iso_arch = File.basename(iso_file,".iso").split(/-/)[1]
      if iso_arch.match(/amd64/)
        iso_arch = "x86_64"
      end
      iso_version = File.basename(iso_file,".iso").split(/-/)[0].gsub(/install/,"").split(//).join(".")
    end
  else
    if iso_file.match(/FreeBSD/)
      iso_info    = File.basename(iso_file).split(/-/)
      iso_distro  = iso_info[0]
      iso_version = iso_info[1]
      if iso_file.match(/amd64/)
        iso_arch = "x86_64"
      else
        iso_arch = "i386"
      end
    else
      if iso_file.match(/coreos/)
        iso_file    = File.basename(iso_file).split(/_/)
        iso_distro  = "coreos"
        iso_version = iso_file[1]
        iso_arch    = "x86_64"
      end
    end
  end
  return iso_distro,iso_version,iso_arch
end

# Get BSD service name from ISO

def get_xb_service_name(iso_file)
  return service_name
end
