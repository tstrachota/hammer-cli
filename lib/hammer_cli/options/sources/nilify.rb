module HammerCLI
  module Options
    module Sources
      class Nilify
        def initialize(nil_placeholder = 'NIL')
          @nil_placeholder = nil_placeholder
        end

        def get_options(defined_options, result)
          result = result.map do |option, value|
            if value == @nil_placeholder
              [option, nil]
            else
              [option, value]
            end
          end.to_h
          result
        end
      end
    end
  end
end
