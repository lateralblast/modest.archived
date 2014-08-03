#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'
require 'mechanize'

puppet_base_url = "http://yum.puppetlabs.com"
puppet_base_dir = "/export/pkgs/puppet"
centos_base_url = "http://mirror.aarnet.edu.au/pub/centos/"
puppet_rpm_list = {}
puppet_rpm_list["products"]     = []
puppet_rpm_list["dependencies"] = []
puppet_rpm_list["products"].push("facter")
puppet_rpm_list["products"].push("hiera")
puppet_rpm_list["products"].push("puppet")
puppet_rpm_list["dependencies"].push("ruby-augeas")
puppet_rpm_list["dependencies"].push("ruby-json")
puppet_rpm_list["dependencies"].push("ruby-shadow")
puppet_rpm_list["dependencies"].push("ruby-rgen")
puppet_rpm_list["dependencies"].push("libselinux-ruby")

[ "5", "6", "7" ].each do |release_dir|
  [ "i386", "x86_64" ].each do |arch_dir|
    centos_rpm_url = centos_base_url+release_dir+"/os/"+arch_dir+"/Packages/"
    [ "products", "dependencies" ].each do |sub_dir|
      puts "Processing '"+sub_dir+"' for Centos/Fedora/SL/RHEL "+release_dir+" for "+arch_dir
      puppet_rpm_url   = puppet_base_url+"/el/"+release_dir+"/"+sub_dir+"/"+arch_dir+"/"
      puppet_local_dir = puppet_base_dir+"/el/"+release_dir+"/"+sub_dir+"/"+arch_dir
      if !File.directory?(puppet_local_dir)
        puts "Creating directory "+puppet_local_dir
        %x[mkdir -p #{puppet_local_dir}]
      end
      puppet_rpm_list[sub_dir].each do |pkg_name|
        if pkg_name.match(/libselinux\-ruby/)
          puppet_rpm_page = Net::HTTP.get(URI.parse(centos_rpm_url))
          rpm_urls = Nokogiri::HTML.parse(puppet_rpm_page).css('td a')
        else
          puppet_rpm_page = Net::HTTP.get(URI.parse(puppet_rpm_url))
          rpm_urls = Nokogiri::HTML.parse(puppet_rpm_page).css('td a')
        end
        pkg_file = rpm_urls.grep(/^#{pkg_name}-[0-9]/)[-1]
        if pkg_file.to_s.match(/href/)
          pkg_file = URI.parse(pkg_file).to_s
          if pkg_name.match(/libselinux\-ruby/)
            pkg_url = centos_rpm_url+pkg_file
          else
            pkg_url = puppet_rpm_url+pkg_file
          end
          local_file = puppet_local_dir+"/"+pkg_file
          if !File.exist?(local_file) or File.size(local_file) == 0
            puts "Fetching "+pkg_url+" to "+local_file
            agent = Mechanize.new
            agent.redirect_ok = true
            agent.pluggable_parser.default = Mechanize::Download
            agent.get(pkg_url).save(local_file)
          end
        end
      end
    end
  end
end
