serial_number = node[:dmi][:system][:serial_number]

dmidecode_pre_file = "/var/preflight/log/#{serial_number}/dmidecode_pre.txt".chomp
ohai_file = "/var/preflight/log/#{serial_number}/ohai.json".chomp
lldp_file = "/var/preflight/log/#{serial_number}/lldp.txt".chomp

bash 'gather_dmidecode_pre' do
  code <<-EOH
    dmidecode > #{dmidecode_pre_file}
  EOH
end

require 'json'
File.open(ohai_file,"w") do |f|
  f.write(node.to_json)
end
