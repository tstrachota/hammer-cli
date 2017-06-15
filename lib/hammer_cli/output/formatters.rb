module HammerCLI::Output
  module Formatters

    # Registry for formatters
    class FormatterLibrary
      def initialize(formatter_map={})

        @_formatters = {}
        formatter_map.each do |type, formatters|
          register_formatter(type, *Array(formatters))
        end
      end

      def register_formatter(type, *formatters)
        if @_formatters[type].nil?
          @_formatters[type] = FormatterContainer.new *formatters
        else
          formatters.each { |f| @_formatters[type].add_formatter(f) }
        end
      end

      def formatter_for_type(type)
        @_formatters[type.name.split('::').last.to_sym]
      end
    end

    # Tags:
    # All the tags the formatter has, needs to be present in the addapter.
    # Otherwise the formatter won't apply. Formatters with :flat tag are used first
    # as we expect them to serialize the value.
    #
    #   - by format: :flat x :data
    #   - by output: :file X :screen

    # abstract formatter
    class FieldFormatter

      def tags
        []
      end

      def match?(other_tags)
        tags & other_tags == tags
      end

      def format(data, field_params={})
        data
      end
    end

    class FormatterContainer < FieldFormatter

      def initialize(*formatters)
        @formatters = formatters
      end

      def add_formatter(*formatters)
        @formatters += formatters
      end

      def format(data, field_params={})
        @formatters.inject(data) { |d,f| f.format(d, field_params) }
      end

    end

    class DateFormatter < FieldFormatter
      def tags
        [:human_readable]
      end

      def format(string_date, field_params={})
        t = DateTime.parse(string_date.to_s)
        t.strftime("%Y/%m/%d %H:%M:%S")
      rescue ArgumentError
        ""
      end
    end

    # TODO:
    # base - format
    # table - format
    # csv - format
    # yaml - return array
    # json - return array
    class ListFormatter < FieldFormatter
      INDENT = "  "

      def tags
        [:flat_values]
      end

      def format(list, field_params={})
        if list.is_a? Array
          separator = field_params.fetch(:separator, ', ')
          new_line = field_params.fetch(:on_new_line, false)

          list = list.join(separator)
          list ="\n#{list.indent_with(INDENT)}" if new_line
          list
        elsif list
          list.to_s
        else
          ""
        end
      end
    end

    # TODO:
    # base - format
    # table - format
    # csv - serialized json?? - design how to do it with parameters
    # yaml - return hash
    # json - return hash
    class KeyValueFormatter < FieldFormatter
      def tags
        [:human_readable]
      end

      def format(params, field_params={})
        if params.is_a? Hash
          name = params[:name] || params["name"]
          value = params[:value] || params["value"]
          "#{name} => #{value}"
        else
          ""
        end
      end
    end

    # TODO:
    # base - format
    # table - remove newlines
    # csv - return original value (string)
    # yaml - return original value (string)
    # json - return original value (string)
    class LongTextFormatter < FieldFormatter
      INDENT = "  "

      def initialize(options = {})
        @indent = options[:indent].nil? ? true : options[:indent]
      end

      def tags
        [:richtext_values]
      end

      def format(text, field_params={})
        text = text.to_s.indent_with(INDENT) if @indent
        "\n#{text}"
      end
    end

    # TODO:
    # base - format
    # table - format
    # csv - cast to boolean
    # yaml - cast to boolean
    # json - cast to boolean
    class BooleanFormatter < FieldFormatter
      def tags
        [:machine_readable]
      end

      def format(value, field_params={})
        !(value == 0 || value.nil? || value == "" || value == false)
      end
    end

    class YesNoFormatter < BooleanFormatter
      def tags
        [:human_readable]
      end

      def format(value, field_params={})
        super ? _("yes") : _("no")
      end
    end

    HammerCLI::Output::Output.register_formatter(DateFormatter.new, :Date)
    HammerCLI::Output::Output.register_formatter(ListFormatter.new, :List)
    HammerCLI::Output::Output.register_formatter(KeyValueFormatter.new, :KeyValue)
    HammerCLI::Output::Output.register_formatter(LongTextFormatter.new, :LongText)

    HammerCLI::Output::Output.register_formatter(BooleanFormatter.new, :Boolean)
    HammerCLI::Output::Output.register_formatter(YesNoFormatter.new, :Boolean)

  end
end



