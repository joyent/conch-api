actions :modify, :enable, :disable

default_action :enable

attribute :ipaddr, :kind_of => String
attribute :netmask, :kind_of => String
attribute :gateway, :kind_of => String
attribute :channel, :kind_of => Integer, :name_attribute => true
attribute :type, :kind_of => String, :default => 'dhcp'
