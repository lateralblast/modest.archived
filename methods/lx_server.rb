# Server related code for Linux related code

# List availabel images

def list_lxc_services()
  puts "Available LXC Images:"
  image_list = Dir.entries($lxc_image_dir)
  image_list.each do |image_name|
    if image_name.match(/tar/)
      image_file = $lxc_image_dir+"/"+image_name
      image_info = File.basename(image_name,".tar.gz")
      image_info = image_info.split(/-/)
      image_os   = image_info[0]
      image_ver  = image_info[1]
      image_arch = image_info[2]
      puts "Distribution:\t"+image_os.capitalize
      puts "Version:\t"+image_ver
      puts "Architecture:\t"+image_arch
      puts "Image File:\t"+image_file
      puts
    end
  end
  return
end
