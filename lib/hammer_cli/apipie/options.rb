
module HammerCLI::Apipie
  module Options

    def method_options(options)
      defaults = add_default_options(resource.action(action).params, options)
      method_options_for_params(resource.action(action).params, options.merge(defaults))
    end

    def method_options_for_params(params, options)
      opts = {}

      params.each do |p|
        if p.expected_type == :hash
          opts[p.name] = method_options_for_params(p.params, options)
        else
          p_name = HammerCLI.option_accessor_name(p.name)
          if options.has_key?(p_name)
            opts[p.name] = options[p_name]
          elsif respond_to?(p_name, true)
            opt = send(p_name)
            opts[p.name] = opt unless opt.nil?
          end
        end
      end

      opts
    end

    def get_option_value(opt_name)
      if respond_to?(HammerCLI.option_accessor_name(opt_name), true)
        send(HammerCLI.option_accessor_name(opt_name))
      else
        nil
      end
    end

    def add_default_options(options, explicit_options)
      defaults = {}
      options.each do |option|
        option = option.name.to_s
        value = HammerCLI::Defaults.get_defaults(option) unless explicit_options["option_"+option]
        if value
          defaults["option_" + option] = value
          logger.info("You are using the following default parameter:  #{option} = #{value}")
        end
      end
      defaults
    end

  end
end
