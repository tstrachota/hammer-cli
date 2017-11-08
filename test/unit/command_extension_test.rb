require 'hammer_cli/command_extension'

require_relative './test_helper'

describe HammerCLI::CommandExtension do

  class Cmd < HammerCLI::AbstractCommand
  end

  class Ext < HammerCLI::CommandExtension
  end

  let(:ext1) { Ext.new }
  let(:ext2) { Ext.new }

  before do
    Cmd.extend_command(ext1)
    Cmd.extend_command(ext2)
  end

  after do
    Cmd.remove_extensions
  end

  let(:cmd) { Cmd.new("", {}) }

  it 'extends help' do
    ext1.expects(:help).with do |builder|
      builder.is_a?(HammerCLI::Help::TextBuilder)
    end
    ext2.expects(:help).with do |builder|
      builder.is_a?(HammerCLI::Help::TextBuilder)
    end
    cmd.help
  end

  it 'extends output' do
    ext1.expects(:output)
    ext2.expects(:output)
    cmd.output_definition
  end

  it 'extends data'
  it 'extends options'
end

