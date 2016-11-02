require File.join(File.dirname(__FILE__), './test_helper')

describe 'config' do
  let(:cmd) { ['config'] }


  it 'requires options' do
    expected_result = usage_error_result(cmd,
      "One of options --paths, --list, --list-by-path is required"
    )
    assert_cmd(expected_result, run_cmd(cmd))
  end

  describe '--paths' do
    it 'prints paths from settings load history' do
      paths = [
        '/etc/hammer/cli_config.yml',
        '/etc/hammer/cli.modules.d/foreman.yml',
        '/home/joe/.hammer/cli_config.yml'
      ]
      settings = stub(:path_history => paths)

      params = ['--paths']
      context = {
        :settings => settings
      }

      expected_result = success_result(Regexp.new(paths.join('\n')))
      assert_cmd(expected_result, run_cmd(cmd + params, context))
    end
  end

  describe '--list' do
    it 'prints complete settings' do
    end
  end

  describe '--list-by-path' do
    it 'prints settings split by path' do
    end
  end
end
