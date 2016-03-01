require 'tty-table'
require File.join(File.dirname(__FILE__), 'wrapper_formatter')

class HammerTableBorder < TTY::Table::Border::ASCII
  def_border do
    top       '-'
    top_mid   '|'
    top_left  ''
    top_right ''
    bottom       '-'
    bottom_mid   '|'
    bottom_left  ''
    bottom_right ''
    mid       '-'
    mid_mid   '|'
    mid_left  ''
    mid_right ''
    left   ''
    center '|'
    right  ''
  end
end

class HammerRenderer < TTY::Table::Renderer::Basic

  def initialize(table, options = {})
    super(table, options.merge(border_class: HammerTableBorder))
  end
end

module HammerCLI::Output::Adapter

  class Table < Abstract

    MAX_COLUMN_WIDTH = 80
    MIN_COLUMN_WIDTH = 5

    def tags
      [:screen, :flat]
    end

    def print_record(fields, record)
      print_collection(fields, [record].flatten(1))
    end

    def print_collection(all_fields, collection)
      fields = field_filter.filter(all_fields)
      headers = fields.map { |f| label_for(f) }

      rows = collection.map do |d|
        fields.map do |f|
          WrapperFormatter.new(
            @formatters.formatter_for_type(f.class), f.parameters).format(data_for_field(f, d) || "")
        end
      end

      table = TTY::Table.new(headers, rows)

      natural_widths = TTY::Table::ColumnSet.new(table).extract_widths
      column_widths = fields.each_with_index.map do |f, i|
        max_width_for(f) || natural_widths[i]
      end

      if table.empty?
        # tty-table doesn't print anything if the table is empty
        table << Array.new(fields.count)
        header_only = true
      end

      renderer = HammerRenderer.new(table,
        :padding => [0,1,0,1],
        :column_widths => column_widths
      )
      output = renderer.render.split("\n")
      output = output.map { |line| line.slice(1..-2) }
      output = output[0..2] if header_only
      puts output.join("\n")
    end

    protected

    def field_filter
      filtered = [Fields::ContainerField]
      filtered << Fields::Id unless @context[:show_ids]
      HammerCLI::Output::FieldFilter.new(filtered)
    end

    private

    def label_for(field)
      width = width_for(field)
      if width
        "%-#{width}s" % field.label.to_s.upcase
      else
        field.label.to_s.upcase
      end
    end

    def max_width_for(field)
      width = width_for(field)
      width ||= field.parameters[:max_width]
      width = MIN_COLUMN_WIDTH if width && width < MIN_COLUMN_WIDTH
      width
    end

    def width_for(field)
      width = field.parameters[:width]
      width = MIN_COLUMN_WIDTH if width && width < MIN_COLUMN_WIDTH
      width
    end

  end

  HammerCLI::Output::Output.register_adapter(:table, Table)

end
