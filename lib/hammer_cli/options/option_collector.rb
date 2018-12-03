module HammerCLI
  module Options
    class OptionCollector
      attr_accessor :option_source

      def initialize(recognised_options, option_source)
        @recognised_options = recognised_options

        if !option_source.is_a?(HammerCLI::Options::SourcesList)
          @option_source = HammerCLI::Options::SourcesList.new(option_source)
        else
          @option_source = option_source
        end
      end

      def all_options_raw
        @all_options_raw ||= @option_source.get_options(@recognised_options, {})
      end

      def all_options
        @all_options ||= translate_nils(all_options_raw)
      end

      def options
        @options ||= all_options.reject { |key, value| value.nil? && all_options_raw[key].nil? }
      end

      private

      def translate_nils(opts)
        Hash[ opts.map { |k,v| [k, translate_nil(v)] } ]
      end

      def translate_nil(value)
        value == HammerCLI::NilValue ? nil : value
      end
    end
  end
end
