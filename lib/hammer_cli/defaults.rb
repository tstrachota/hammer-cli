require 'hammer_cli'
require 'yaml'
module HammerCLI

  class DefaultsCommand < HammerCLI::AbstractCommand

    class ListDefaultsCommand < HammerCLI::DefaultsCommand
      command_name 'list'

      desc _('List all the defaults parameters')
      def execute
        list_all_defaults_message
        HammerCLI::EX_OK
      end
    end

    class AddDefaultsCommand < HammerCLI::DefaultsCommand
      command_name 'add'

      desc _('Add a default parameter to config')
      option "--param-name", "Option_name", _("The name of the default option"), :required => true
      option "--param-val", "Option_value", _("The value for the default option")
      option "--plugin-name", "Option_name", _("The plugin name defaults will be generated for")

      def execute
        begin
          if option_plugin_name.nil? && option_param_val.nil? || !option_plugin_name.nil? && !option_param_val.nil?
            bad_input
          else
            namespace = ("HammerCLI" + option_plugin_name.split('_').collect!{ |w| w.downcase.capitalize }.join + "::Defaults") if option_plugin_name
            if option_plugin_name
              raise NameError unless HammerCLI::Defaults.providers.any? {|p| p.to_s.include? namespace}
              raise NotImplementedError unless HammerCLI::Defaults.providers[0].support? option_param_name
            end
            Defaults.add_defaults_to_conf({option_param_name => option_param_val},option_plugin_name ? HammerCLI::Defaults.providers.find_index(namespace.constantize) : "")
            added_default_message(option_param_name.to_s, option_param_val ? option_param_val.to_s : "that will be generated from the server")
          end
          rescue NameError => e
          plugin_prob_message
          rescue StandardError => e
          file_not_found_message
          rescue NotImplementedError => e
          defaults_not_supproted_by_plugin
          HammerCLI::EX_CONFIG
        end
        HammerCLI::EX_OK
      end
    end

    def added_default_message(key, value)
        print_message(_("Added " + %{key_val} + " default-option with value %{val_val}.") % {:key_val => key.to_s,:val_val => value.to_s } )
    end

    def plugin_prob_message
      print_message(_("Couldn't reach the plugin defaults class, eiter the plugin doesn't have defaults class or the plugin misspelled.(example, for Hammer_CLI_Foreman --plugin-name foreman)"))
    end

    def defaults_not_supproted_by_plugin
      print_message(_("The param name is not supported by plugin"))
    end


    def bad_input
      print_message(_("You must specify a value or a plugin name, cant specify both."))
    end

    def self.file_cant_be_created
      print_message(_("Couldn't add file to ~/.hammer/cli.modules.d please create the path before defaults will be enabled."))
    end

    def list_all_defaults_message
      HammerCLI::Settings.settings[:defaults].each do |key,val|
          print_message('')
          print_message(key.to_s+":")
          print_message(YAML.dump(HammerCLI::Settings.settings[:defaults][key]))
      end
    end

    autoload_subcommands
  end


  class Defaults
    def self.register_provider(provider)
      Defaults.providers << provider
    end

    def self.providers
      @@providers ||= []
    end

    def self.add_defaults_to_conf(options, provider)
      create_default_file unless !defaults_file_exists?
      path = "#{Dir.home}/.hammer/cli.modules.d/defaults.yml"
      new_file = YAML.load_file(path)
      options.each do |key, value|
        key = key.to_sym
        value.to_s.to_i if value.is_a? Integer
        new_file[:defaults] = {} if new_file[:defaults].nil?
        new_file[:defaults][key] = value ? {:value => value, :from_server => false} : {:from_server => true, :provider => provider}
      end
      File.open(path,'w') do |h|
        h.write new_file.to_yaml
      end
    end

    #this method will be overriden by plugins who wish to have a defaults params.
    def self.get_defaults(option)
      unless HammerCLI::Settings.settings[:defaults].nil? || HammerCLI::Settings.settings[:defaults][option.to_sym].nil?
        if HammerCLI::Settings.settings[:defaults][option.to_sym][:from_server]
          value =  HammerCLI::Defaults.providers[HammerCLI::Settings.settings[:defaults][option.to_sym][:provider]].get_defaults(option.to_sym)
          value
        else
          value = HammerCLI::Settings.settings[:defaults][option.to_sym][:value] if defaults_file_exists?
          value
        end
      end
    end

    def self.defaults_file_exists?
      HammerCLI::Settings.settings[:defaults].nil?
    end


    def self.create_default_file
      path = "#{Dir.home}/.hammer/cli.modules.d/"
      if Dir.exist?(path)
        new_file = File.new(path + "/defaults.yml", "w")
        new_file.write ":defaults:"
        new_file.close
      else
        DefaultsCommand.file_cant_be_created
      end

    end

  HammerCLI::MainCommand.subcommand "defaults", _("Defaults management"), HammerCLI::DefaultsCommand
end
end