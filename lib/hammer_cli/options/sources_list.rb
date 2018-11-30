module HammerCLI
  module Options
    class SourcesList < Array
      def insert_relative(mode, target_name, source)
        index = target_name.nil? ? nil : item_index(target_name)
        HammerCLI.insert_relative(self, mode, index, source)
      end

      def find_by_name(name)
        self[item_index(name)]
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
