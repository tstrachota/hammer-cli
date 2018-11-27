require_relative './base_validator'
require_relative './dsl'

module HammerCLI
  module Options
    module Validation
      class DSLBlockValidator < BaseValidator
        def initialize(&block)
          @validation_block = block
        end

        def run(options, option_values)
          dsl = DSL.new(options, option_values)
          dsl.run(&@validation_block)
        end
      end
    end
  end
end
