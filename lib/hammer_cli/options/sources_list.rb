module HammerCLI
  module Options
    class SourcesList < Array
      attr_reader :name

      def initialize(sources = [], name: nil)
        @name = name
        self.push(*sources)
      end

      def insert_relative(mode, target_name, source)
        index = target_name.nil? ? nil : item_index(target_name)
        HammerCLI.insert_relative(self, mode, index, source)
      end

      def find_by_name(name)
        self[item_index(name)]
      end

      def get_options(defined_options, result)
        self.inject(result) do |all_options, source|
          if source.respond_to?(:get_options)
            source.get_options(defined_options, all_options)
          else
            source.run(defined_options, all_options)
            all_options
          end
        end
      end

      private

      def item_index(target_name)
        idx = find_index do |item|
          item.respond_to?(:name) && (item.name == target_name)
        end
        raise ArgumentError, "Option source '#{target_name}' not found" if idx.nil?
        idx
      end
    end
  end
end
