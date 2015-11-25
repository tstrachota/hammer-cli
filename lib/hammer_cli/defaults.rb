require 'hammer_cli'
require 'yaml'
module HammerCLI

  class BaseDefaultsProvider
    def self.plugin_name
      self.name.split('::').first.gsub(/^HammerCLI/, '').underscore
    end

    def self.register_provider
      HammerCLI.defaults.register_provider(self)
    end

    def self.support?
      raise NotImplementedError
    end

    def self.get_defaults
      raise NotImplementedError
    end
  end

  class DefaultsCommand < HammerCLI::AbstractCommand

    class ListDefaultsCommand < HammerCLI::DefaultsCommand
      command_name 'list'

      desc _('List all the default parameters')
      def execute
        list_all_defaults_message
        HammerCLI::EX_OK
      end
    end

    class DeleteDefaultsCommand < HammerCLI::DefaultsCommand
      command_name 'delete'

      desc _('Delete a default param')
      option "--param-name", "OPTION_NAME", _("The name of the default option"), :required => true

      def execute
        if context[:defaults].defaults_settings && context[:defaults].defaults_settings[option_param_name.to_sym]
          context[:defaults].delete_default_from_conf(option_param_name.to_sym)
          param_deleted(option_param_name)
        else
          variable_not_found
        end
        HammerCLI::EX_OK
      end
    end

    class AddDefaultsCommand < HammerCLI::DefaultsCommand
      command_name 'add'

      desc _('Add a default parameter to config')
      option "--param-name", "OPTION_NAME", _("The name of the default option"), :required => true
      option "--param-val", "OPTION_VALUE", _("The value for the default option")
      option "--plugin-name", "OPTION_PLUGIN_NAME", _("The plugin name defaults will be generated for")

      def execute
        if option_plugin_name.nil? && option_param_val.nil? || !option_plugin_name.nil? && !option_param_val.nil?
          bad_input
          HammerCLI::EX_USAGE
        else
          if option_plugin_name
            namespace = option_plugin_name
            if !context[:defaults].providers.key?(namespace)
              plugin_prob_message
              return HammerCLI::EX_USAGE
            elsif !context[:defaults].providers[namespace].support?(option_param_name)
              defaults_not_supproted_by_plugin
              return HammerCLI::EX_CONFIG
            end
          end
          context[:defaults].add_defaults_to_conf({option_param_name => option_param_val}, namespace)
          added_default_message(option_param_name.to_s, option_param_val)
          HammerCLI::EX_OK
        end
      rescue Defaults::DefaultsError, SystemCallError => e
        print_message(e.message)
        HammerCLI::EX_CONFIG
      end
    end

    def added_default_message(key, value)
      print_message(_("Added %{key_val} default-option with value that will be generated from the server.") % {:key_val => key.to_s} ) if value.nil?
      print_message(_("Added %{key_val} default-option with value %{val_val}.") % {:key_val => key.to_s, :val_val=> value.to_s} ) unless value.nil?
    end

    def plugin_prob_message
      print_message(_("Couldn't reach the plugin defaults class, eiter the plugin doesn't have defaults class or the plugin misspelled.(example, for Hammer_CLI_Foreman --plugin-name foreman)"))
    end

    def defaults_not_supproted_by_plugin
      print_message(_("The param name is not supported by plugin."))
    end

    def param_deleted(param)
      print_message(_("%{param} was deleted successfully.") % {:param => param.to_s})
    end

    def bad_input
      print_message(_("You must specify value or a plugin name, cant specify both."))
    end

    def variable_not_found
      print_message(_("Couldn't find the requested param in %s.") % context[:defaults].path)
    end

    def list_all_defaults_message
      unless context[:defaults].defaults_settings.nil?
        print_message("--------------------")
        print_message("Hammer defaults list")
        print_message("--------------------")
        context[:defaults].defaults_settings.each do |key,val|
          if val[:from_server]
            print_message(key.to_s + " : " +  _("(provided by %{plugin})") % {:plugin => val[:provider].to_s.split(':').first.gsub("HammerCLI", '')})
          else
            print_message(key.to_s + " : " + val[:value].to_s)
          end
        end
      else
        print_message(_("No defaults file was found"))
      end
    end

    autoload_subcommands
  end


  class Defaults
    DEFAULT_FILE = "#{Dir.home}/.hammer/cli.modules.d/defaults.yml"

    class DefaultsError < StandardError; end
    class DefaultsPathError < DefaultsError; end

    attr_reader :defaults_settings

    def initialize(settings, file_path = nil)
      @defaults_settings = settings
      @path = file_path || DEFAULT_FILE
    end

    def register_provider(provider)
      providers[provider.plugin_name.to_s] = provider
    end

    def providers
      @providers ||= {}
    end

    def delete_default_from_conf(param)
      conf_file = YAML.load_file(path)
      conf_file[:defaults].delete(param)
      write_to_file conf_file
      conf_file
    end

    def add_defaults_to_conf(default_options, provider)
      create_default_file if defaults_settings.nil?
      defaults = YAML.load_file(path)
      defaults[:defaults] ||= {}
      default_options.each do |key, value|
        key = key.to_sym
        defaults[:defaults][key] = value ? {:value => value, :from_server => false} : {:from_server => true, :provider => provider}
      end
      write_to_file defaults
      defaults
    end

    def get_defaults(option)
      unless defaults_settings.nil? || defaults_settings[option.to_sym].nil?
        if defaults_settings[option.to_sym][:from_server]
          providers[defaults_settings[option.to_sym][:provider]].get_defaults(option.to_sym)
        else
          defaults_settings[option.to_sym][:value]
        end
      end
    end

    def write_to_file(defaults)
      File.open(path,'w') do |h|
        h.write defaults.to_yaml
      end
    end

    protected

    attr_reader :path

    def create_default_file
      if Dir.exist?(File.dirname(@path))
        new_file = File.new(path, "w")
        new_file.write ":defaults:"
        new_file.close
      else
        raise DefaultsPathError.new(_("Couldn't create %s please create the path before defaults will be enabled.") % path)
      end
    end
  end

  def self.defaults
    @defaults ||= Defaults.new(HammerCLI::Settings.settings[:defaults])
  end

  HammerCLI::MainCommand.subcommand "defaults", _("Defaults management"), HammerCLI::DefaultsCommand
end
