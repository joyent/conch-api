actions :modify, :enable, :disable

default_action :enable

attribute :username, :kind_of => String
attribute :password, :kind_of => String
# 1 - Callback, 2 - User, 3 - Operator, 4- Administrator
attribute :level, :kind_of => Integer, :equal_to => [1, 2, 3, 4]
attribute :channel, :kind_of => Integer, :default => 1
attribute :userid, :kind_of => Integer, :name_attribute => true
