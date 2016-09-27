module TablePrint
  class FixedWidthFormatter
    def format(value)
      padding = width - strip_escape(value.to_s).each_char.collect{|c| c.bytesize == 1 ? 1 : 2}.inject(0, &:+)
      truncate(value) + (padding < 0 ? '' : " " * padding)
    end

    private

    def truncate(value)
      return "" unless value

      value = value.to_s
      return value unless strip_escape(value).length > width

      "#{value[0..width-4]}..."
    end

    def strip_escape(value)
      value.gsub(/[\u0080-\u00ff]/, ' ')
    end
  end
end
