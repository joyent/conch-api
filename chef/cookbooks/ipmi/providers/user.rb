#
# Cookbook Name:: ipmi
# Provider:: user
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
  execute 'ipmitool set user name' do
    command "ipmitool user set name #{new_resource.userid} #{new_resource.username}"
    only_if { new_resource.username }
  end
  execute 'ipmitool set user password' do
    command "ipmitool user set password #{new_resource.userid} #{new_resource.password}"
    only_if { new_resource.password }
  end
  execute 'ipmitool user priv' do
    command "ipmitool user priv #{new_resource.userid} #{new_resource.level} #{new_resource.channel}"
    only_if { new_resource.level }
  end
end

action :enable do
  execute 'ipmitool user enable' do
    command "ipmitool user enable #{new_resource.userid}"
  end
end

action :disable do
  execute 'ipmitool user disable' do
    command "ipmitool user disable #{new_resource.userid}"
  end
end
