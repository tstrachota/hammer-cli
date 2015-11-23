require File.join(File.dirname(__FILE__), '../unit/test_helper')

describe 'commands' do

  class TestProvider < HammerCLI::BaseDefaultsProvider
    def self.support?(param)
      param.to_s == 'organization_id'
    end

    def self.get_defaults(param)
      32
    end
  end

  before do
    @defaults = mock()
    @defaults.stubs(:providers).returns({
      :foreman => TestProvider
    })

    @context = {
      :defaults => @defaults
    }
  end

  EXPECTED_HEADER = [
    '--------------------',
    'Hammer defaults list',
    '--------------------',
    ''
  ].join("\n")

  def run_cmd(cmd_class, options)
    capture_io do
      cmd_class.run('hammer', options, @context)
    end
  end

  describe 'defaults list' do

    it 'it prints all defaults' do
      default_values = {
        :organization_id => {
          :value => 3,
          :from_server => false
        },
        :location_id => {
          :from_server => true,
          :provider => 'HammerCLIForeman::Defaults'
        }
      }
      @defaults.stubs(:defaults_settings).returns(default_values)

      expected_output = EXPECTED_HEADER + [
        'organization_id : 3',
        'location_id : (provided by Foreman)',
        ''
      ].join("\n")

      out, err = run_cmd(HammerCLI::DefaultsCommand::ListDefaultsCommand, [])
      assert_equal "", err
      assert_equal expected_output, out
    end

    it 'prints empty defaults' do
      @defaults.stubs(:defaults_settings).returns({})

      out, err = run_cmd(HammerCLI::DefaultsCommand::ListDefaultsCommand, [])
      assert_equal "", err
      assert_equal EXPECTED_HEADER, out
    end

  end

  describe 'defaults add' do
    it 'adds static default' do
      options = ['--param-name=param', '--param-val=83']

      @defaults.expects(:add_defaults_to_conf).with({'param' => '83'}, nil).once

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_equal "Added param default-option with value 83.\n", out
    end

    it 'adds default from provider' do
      options = ['--param-name=organization_id', '--plugin-name=foreman']

      @defaults.expects(:add_defaults_to_conf).with({'organization_id' => nil}, :foreman).once

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_equal "Added organization_id default-option with value that will be generated from the server.\n", out
    end

    it 'reports unsupported option' do
      options = ['--param-name=unsupported', '--plugin-name=foreman']

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_equal "The param name is not supported by plugin.\n", out
    end

    it 'reports missing parameter name' do
      options = ['--param-val=83']

      out, err = capture_io do
        HammerCLI::DefaultsCommand::AddDefaultsCommand.run('hammer', options, @context)
      end
      assert_match "option '--param-name' is required", err
      assert_equal "", out
    end

    it 'reports missing parameter value or source' do
      options = ['--param-name=organization_id']

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_match "You must specify value or a plugin name, cant specify both.", out
    end

    it 'reports unknown plugin' do
      options = ['--param-name=organization_id', '--plugin-name=unknown']

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_equal "Couldn't reach the plugin defaults class, eiter the plugin doesn't have defaults class or the plugin misspelled.(example, for Hammer_CLI_Foreman --plugin-name foreman)\n", out
    end

    it 'reports missing defaults file' do
      options = ['--param-name=param', '--param-val=83']

      @defaults.expects(:add_defaults_to_conf).raises(Errno::ENOENT)

      out, err = run_cmd(HammerCLI::DefaultsCommand::AddDefaultsCommand, options)
      assert_equal "", err
      assert_equal "Couldn't open the defaults file.\n", out
    end
  end

  describe 'defaults delete' do
    it 'removes the defaults' do
      default_values = {
        :organization_id => {
          :value => 3,
          :from_server => false
        }
      }
      @defaults.stubs(:defaults_settings).returns(default_values)
      @defaults.expects(:delete_default_from_conf).once

      options = ['--param-name=organization_id']

      out, err = run_cmd(HammerCLI::DefaultsCommand::DeleteDefaultsCommand, options)
      assert_equal "", err
      assert_equal "organization_id was deleted successfully.\n", out
    end

    it 'reports when the variable was not found' do
      @defaults.stubs(:defaults_settings).returns({})
      @defaults.stubs(:path).returns('/path/to/defaults.yml')

      options = ['--param-name=organization_id']

      out, err = run_cmd(HammerCLI::DefaultsCommand::DeleteDefaultsCommand, options)
      assert_equal "", err
      assert_equal "Couldn't find the requested param in /path/to/defaults.yml.\n", out
    end
  end

end

