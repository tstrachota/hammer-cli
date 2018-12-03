module HammerCLI
  module Options
    module Sources
      class Abstract
        def initialize(name: nil)
          @name = name
        end

        def name
          @name || self.class.name.split('::')[-1]
        end

        def get_options(defined_options, result)
          result
        end
      end
    end
  end
end
