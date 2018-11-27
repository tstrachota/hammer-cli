module HammerCLI
  module Options
    module Validation
      class ValidationError < StandardError
      end

      class BaseValidator
        def run(options, option_values)
        end
      end
    end
  end
end
