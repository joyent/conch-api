#
# Cookbook Name:: ipmi
# Recipe:: default
#
# Copyright 2012, LivingSocial
# Author: Paul Thomas <paul.thomas@livingsocial.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'ohai'

# install the appropriate ipmi packages per platform
case node['platform_family']
when 'debian', 'freebsd', 'rhel'
  node['ipmi_cookbook']['packages'].each do |pkg|
    package pkg
  end
end

node['ipmi_cookbook']['kernel_modules'].each do |kmodule|
  kernel_module kmodule do
    action :install
  end
end

service 'ipmievd' do
  supports :status => true, :restart => true
  action [:enable, :start]
end

cookbook_file "#{node['ohai']['plugin_path']}/ipmi.rb" do
  owner 'root'
  group 'root'
  mode '0644'
  source 'ohai_ipmi.rb'
end
