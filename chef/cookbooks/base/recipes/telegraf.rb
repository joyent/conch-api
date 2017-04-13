serial_number = node[:dmi][:system][:serial_number]

%w{
  /var/tmp/telegraf
  /var/tmp/telegraf/telegraf.d
  /var/tmp/telegraf/plugins
}.each do |dir|
  directory dir
end

# Ex: va2-1-e02-1-test
# region-datacenter-rack-switch-desc

iface = node[:lldp].keys.first
chassis = node[:lldp][iface][:chassis][:name]
a = chassis.split("-")
datacenter = "#{a[0]}-#{a[1]}"
rack = a[2]

puts "XXX LOCATION #{datacenter} #{rack}"

template "/var/tmp/telegraf/plugins/ipmi.sh" do
  source "telegraf_plugins/ipmi.sh"
  mode 0755
  variables({
    :serial_number => serial_number
  })
end

cookbook_file "/etc/default/hddtemp" do
  source "hddtemp"
end

template "/var/tmp/telegraf/telegraf.conf" do
  source "telegraf.conf.erb"
  variables({
    :datacenter => datacenter,
    :rack => rack,
    :serial_number => serial_number
  })
end

template "/var/tmp/telegraf/telegraf.d/output_influx.conf" do
  source "telegraf.d/output_influx.conf.erb"
end

# XXX systemd is installed, but not in use in this environemnt, so we can't
# XXX use the service provider.

%w{
  telegraf
  hddtemp
}.each do |svc|
  execute "start_#{svc}" do
    command "service #{svc} start"
  end
end
