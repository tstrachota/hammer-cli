require File.join(File.dirname(__FILE__), 'test_helper')
require 'tempfile'

describe HammerCLI::Defaults do
  FILEPATH = File.join(File.dirname(__FILE__), '/fixtures/defaults/defaults.yml')

  before(:all) do
    HammerCLI::Settings::load(YAML::load(File.open(FILEPATH)))
    HammerCLI::Defaults.stubs(:path).returns FILEPATH
    HammerCLI::Defaults.stubs(:write_to_file).returns true
  end

  it "Should add a default param to defaults file, without a provider" do
    defaults_result = HammerCLI::Defaults.add_defaults_to_conf({"organization_id"=> 3}, nil)
    assert_equal  defaults_result[:defaults][:organization_id][:value], 3
    assert_equal  defaults_result[:defaults][:organization_id][:from_server], false
  end

  it "Should add a default param to defaults file, with provider" do
    defaults_result = HammerCLI::Defaults.add_defaults_to_conf({"organization_id"=>nil}, :foreman)
    assert_equal defaults_result[:defaults][:organization_id][:provider], :foreman
    assert_equal defaults_result[:defaults][:organization_id][:from_server], true
  end

  it "Should remove default param from defaults file" do
    defaults_result = HammerCLI::Defaults.delete_default_from_conf(:organization_id)
    assert_nil defaults_result[:defaults][:organization_id]
  end

  it "should get the default param, without provider" do

    assert_equal HammerCLI::Defaults.get_defaults("location_id"), 2
  end

  it "should get the default param, with provider" do
    #simulating HammerCli as a provider
    HammerCLI::Defaults.stubs(:providers).returns HammerCLI
    HammerCLI::Defaults.stubs(:get_defaults).returns 3
    assert_equal HammerCLI::Defaults.get_defaults("organization_id") ,3
    HammerCLI::Defaults.unstub(:get_defaults)
  end


end
