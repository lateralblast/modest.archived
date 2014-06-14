# Common *BSD code

# List ISOs

def list_bsd_isos(search_string)
  puts
  iso_list      = check_iso_base_dir(search_string)
  iso_list.each do |iso_file_name|
    iso_file_name = iso_file_name.chomp
    (bsd_distro,iso_version,iso_arch) = get_bsd_version_info(iso_file_name)
    puts "ISO file:\t"+iso_file_name
    puts "Distribution:\t"+bsd_distro
    puts "Version:\t"+iso_version
    puts "Architecture:\t"+iso_arch
    service_name     = bsd_distro.downcase+"_"+iso_version.gsub(/\./,"_")+"_"+iso_arch
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

def get_bsd_version_info(iso_file)
  if iso_file.match(/install/)
    bsd_distro  = "OpenBSD"
    if !iso_file.match(/i386|x86_64|amd64/)
      iso_arch = %x[strings #{iso_file} |head -2 |tail -1 |awk '{print $2}'].split(/\//)[1].chomp
      iso_version = File.basename(iso_file,".iso").gsub(/install/,"").split(//).join(".")
    else
      iso_arch = File.basename(iso_file,".iso").split(/-/)[1]
      if iso_arch.match(/amd64/)
        iso_arch = "x86_64"
      end
      iso_version = File.basename(iso_file,".iso").split(/-/)[0].gsub(/install/,"").split(//).join(".")
    end
  else
    iso_info    = File.basename(iso_file).split(/-/)
    bsd_distro  = iso_info[0]
    iso_version = iso_info[1]
    if iso_file.match(/amd64/)
      iso_arch = "x86_64"
    else
      iso_arch = "i386"
    end
  end
  return bsd_distro,iso_version,iso_arch
end

# Get BSD service name from ISO

def get_xb_service_name(iso_file)
  return service_name
end
