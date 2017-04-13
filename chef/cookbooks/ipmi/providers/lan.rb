#
# Cookbook Name:: ipmi
# Provider:: lan
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

def whyrun_supported?
  true
end

action :modify do
  if new_resource.type == 'static'
    execute 'ipmitool lan set ipsrc static' do
      command "ipmitool lan set #{new_resource.channel} ipsrc static"
      not_if "ipmitool lan print 1 | grep 'IP Address Source' | awk '{print $5}' | grep -q 'Static'"
    end
    execute 'ipmitool lan set ipaddr' do
      command "ipmitool lan set #{new_resource.channel} ipaddr #{new_resource.ipaddr}"
      only_if { new_resource.ipaddr }
      not_if "ipmitool lan print 1 | grep 'IP Address' | awk '{print $4'} | grep -q '#{new_resource.ipaddr}'"
    end
    execute 'ipmitool lan set netmask' do
      command "ipmitool lan set #{new_resource.channel} netmask #{new_resource.netmask}"
      only_if { new_resource.netmask }
      not_if "ipmitool lan print 1 | grep 'Subnet Mask' | awk '{print $4'} | grep -q '#{new_resource.netmask}'"
    end
    execute 'ipmitool lan set defgw' do
      command "ipmitool lan set #{new_resource.channel} defgw ipaddr #{new_resource.gateway}"
      only_if { new_resource.gateway }
      not_if "ipmitool lan print 1 | grep 'Default Gateway IP' | awk '{print $5'} | grep -q '#{new_resource.gateway}'"
    end
  elsif new_resource.type == 'dhcp'
    execute 'ipmitool lan set ipsrc dhcp' do
      command "ipmitool lan set #{new_resource.channel} ipsrc dhcp"
      not_if "ipmitool lan print 1 | grep 'IP Address Source' | awk '{print $5}' | grep -q 'DHCP'"
    end
  end
end

action :enable do
  execute 'ipmitool lan set access on' do
    command "ipmitool lan set #{new_resource.channel} access on"
  end
end

action :disable do
  execute 'ipmitool lan set access off' do
    command "ipmitool lan set #{new_resource.channel} access off"
  end
end
