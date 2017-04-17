serial_number = node[:dmi][:system][:serial_number]

%w{
  /etc/chef
  /etc/chef/ohai_plugins
  /var/preflight
  /var/preflight/bin
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

service 'cron' do
  action [:enable, :start]
end

ohai 'reload' do
  action :reload
end

cookbook_file "/etc/chef/ohai_plugins/lldp.rb" do
  source "plugins/lldp.rb"
  notifies :reload, "ohai[reload]"
end

%w{
  export.pl
  sas3ircu
}.each do |file|
  cookbook_file "/var/preflight/bin/#{file}" do
    source "bin/#{file}"
    mode 0755
  end
end

directory "/var/preflight/log/#{serial_number}"

cron 'exporter' do
  command "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/srvadmin/sbin /var/preflight/bin/export.pl > /var/preflight/log/export.log 2>&1"
end

include_recipe "base::report"
include_recipe "base::telegraf"
