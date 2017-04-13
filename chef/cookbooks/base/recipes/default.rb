serial_number = node[:dmi][:system][:serial_number]

%w{
  /etc/chef
  /etc/chef/ohai_plugins
  /var/preflight
  /var/preflight/log
}.each do |dir|
  directory dir
end

node[:network][:interfaces].keys.sort.each do |iface|
  execute "bringup_#{iface}" do
    command "ifconfig #{iface} up"
  end
end

service 'lldpd' do
  action [:enable, :start]
end

ohai 'reload' do
  action :reload
end

cookbook_file "/etc/chef/ohai_plugins/lldp.rb" do
  source "plugins/lldp.rb"
  notifies :reload, "ohai[reload]"
end

directory "/var/preflight/log/#{serial_number}"

include_recipe "base::report"
include_recipe "base::telegraf"
