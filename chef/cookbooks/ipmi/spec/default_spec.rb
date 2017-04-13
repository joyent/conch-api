require 'spec_helper'

describe 'ipmi::default' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(platform: 'ubuntu', version: '12.04')
    runner.converge 'ipmi::default'
  end
  subject { chef_run }

end
