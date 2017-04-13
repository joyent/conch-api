#
# Cookbook Name:: ohai
# Plugin:: ipmi
# Copyright:: 2012, John Dewey
# Copyright:: 2013-2014, Limelight Networks, Inc.
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
# Acquired from: https://bitbucket.org/retr0h/ohai.git

Ohai.plugin(:Ipmi) do
  provides 'ipmi'

  collect_data(:linux) do
    begin

      # gather IPMI interface information
      so = shell_out('ipmitool lan print')

      if so.exitstatus == 0
        ipmi Mash.new
        so.stdout.lines do |line|
          case line
          when /IP Address\s+: ([0-9.]+)/
            ipmi[:address] = Regexp.last_match[1]
          when /Default Gateway IP\s+: ([0-9.]+)/
            ipmi[:gateway] = Regexp.last_match[1]
          when /Subnet Mask\s+: ([0-9.]+)/
            ipmi[:mask] = Regexp.last_match[1]
          when /MAC Address\s+: ([a-z0-9:]+)/
            ipmi[:mac_address] = Regexp.last_match[1]
          when /IP Address Source\s+: (.+)/
            ipmi[:ip_source] = Regexp.last_match[1]
          end
        end
      end

      # gather IPMI System Event Log information
      so = shell_out('ipmitool sel info')

      if so.exitstatus == 0
        ipmi[:sel] = Mash.new
        so.stdout.lines do |line|
          case line
          when /^Version\s+: (\d+(\.\d+)+)/
            ipmi[:sel][:version] = Regexp.last_match[1]
          when /^Entries\s+: (.+)/
            ipmi[:sel][:entries] = Regexp.last_match[1].to_i
          when /^Percent Used\s+: ([0-9]+)/
            ipmi[:sel][:percent_used] = Regexp.last_match[1].to_i
          when /^Overflow\s+: ([a-z]+)/
            ipmi[:sel][:overflow] = Regexp.last_match[1] == 'true' ? true : false
          end
        end
      end

      # gather IPMI Management Controller information
      so = shell_out('ipmitool mc info')

      if so.exitstatus == 0
        ipmi[:mc] = Mash.new
        so.stdout.lines do |line|
          case line
          when /^Device Revision\s+: (.+)/
            ipmi[:mc][:device_revision] = Regexp.last_match[1]
          when /^Firmware Revision\s+: (.+)/
            ipmi[:mc][:firmware_revision] = Regexp.last_match[1]
          when /^IPMI Version\s+: (.+)/
            ipmi[:mc][:ipmi_version] = Regexp.last_match[1]
          when /^Manufacturer ID\s+: (.+)/
            ipmi[:mc][:manufacturer_id] = Regexp.last_match[1]
          when /^Product ID\s+: (.+)/
            ipmi[:mc][:product_id] = Regexp.last_match[1]
          end
        end
      end

    rescue
      Chef::Log.warn 'Ohai ipmi plugin failed to run'
    end
  end
end
