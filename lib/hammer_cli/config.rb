require 'hammer_cli/abstract'

module HammerCLI
  class ConfigCommand < AbstractCommand

    option '--paths', :flag, _("Show only used paths")
    option '--list', :flag, _("List final configuration")
    option '--list-by-path', :flag, _("List configurations from each of used files")

    def validate_options
      validator.one_of(:option_paths, :option_list, :option_list_by_path).required
    end

    def execute
      if option_paths?
        puts context[:settings].path_history
      elsif option_list?
        puts context[:settings].settings.to_yaml
      elsif option_list_by_path?
        context[:settings].path_history.each do |cfg_file|
          puts cfg_file
          puts YAML::load(File.open(cfg_file)).to_yaml
          puts
        end
      end
      HammerCLI::EX_OK
    end
  end

  HammerCLI::MainCommand.subcommand "config", _("Print current hammer config"), HammerCLI::ConfigCommand
end
