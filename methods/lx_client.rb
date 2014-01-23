# Code for LXC clients

# List availabel clients

def list_lxcs()
  puts "Available LXC clients:"
  client_list = Dir.entries($lxc_base_dir)
  client_list.each do |client_name|
    client_name = client_name.chomp
    puts client_name
  end
  return
end
