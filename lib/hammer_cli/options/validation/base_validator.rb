module HammerCLI
  module Options
    module Validation
      class ValidationError < StandardError
      end

      class BaseValidator
        def name
          self.class.name.split('::')[-1]
        end

        def run(options, option_values)
        end
      end
    end
  end
end
