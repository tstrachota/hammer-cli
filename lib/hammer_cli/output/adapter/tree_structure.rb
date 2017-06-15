module HammerCLI::Output::Adapter
  class TreeStructure < Abstract

    def initialize(context={}, formatters={})
      super
      @paginate_by_default = false
    end

    def prepare_collection(fields, collection)
      collection.map do |element|
        render_fields(fields, element)
      end
    end

    protected
    def field_filter
      filtered = []
      filtered << Fields::Id unless @context[:show_ids]
      HammerCLI::Output::FieldFilter.new(filtered)
    end

    def filter_fields(fields, data)
      field_filter.filter(fields).reject do |field|
        field_data = data_for_field(field, data)
        !field.display?(field_data) || !field.applicable?(tags)
      end
    end

    def render_fields(fields, data)
      fields = filter_fields(fields, data)

      fields.reduce({}) do |hash, field|
        field_data = data_for_field(field, data)
        hash.update(field.label => render_field(field, field_data))
      end
    end

    def render_field(field, data)
      if field.is_a? Fields::ContainerField
        if data.is_a? Array
          data.map do |item|
            result = render_fields(field.fields, item)
            if (result.size == 1) && result[nil]
              result[nil]
            else
              result
            end
          end
        else
          render_fields(field.fields, data)
        end

        # render_fields(field.fields, data)

        # fields_data = data.map do |d|
        #   render_fields(field.fields, d)
        # end
        # render_data(field, map_data(fields_data))
      else
        formatter = @formatters.formatter_for_type(field.class)
        parameters = field.parameters
        parameters[:context] = @context
        if formatter
          data = formatter.format(data, field.parameters)
        end
        data
      end
    end

    def render_data(field, data)
      if field.is_a?(Fields::Collection)
        if(field.parameters[:numbered])
          numbered_data(data)
        else # necislovana kolekce je pole
          data
        end
      else
        data.first
      end
    end

    def map_data(data)
      if data.any? { |d| d.key?(nil) }
        data.map! { |d| d.values.first }
      end
      data
    end

    def numbered_data(data)
      i = 0
      data.inject({}) do |hash, value|
        i += 1
        hash.merge(i => value)
      end
    end

  end
end
