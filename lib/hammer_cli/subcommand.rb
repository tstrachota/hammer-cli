
module HammerCLI

  module Subcommand

    class DeprecateCommand < Clamp::Subcommand::Definition

      def initialize(names, description, subcommand_class_name, hidden = false, deprecated = false)
        @names = Array(names)
        @description = description
        @subcommand_class_name = subcommand_class_name
        @hidden = hidden
        @deprecated = deprecated
      end

      def hidden?
        @hidden
      end

      def deprecated?
        @deprecated
      end

    end

    class LazyDefinition < DeprecateCommand

      def initialize(names, description, subcommand_class_name, path, hidden = false, deprecated = false)
        @names = Array(names)
        @description = description
        @subcommand_class_name = subcommand_class_name
        @path = path
        @hidden = hidden
        @deprecated = deprecated
        @loaded = false
      end

      def loaded?
        @loaded
      end

      def subcommand_class
        if !@loaded
          require @path
          @loaded = true
          @constantized_class = @subcommand_class_name.constantize
        end
        @constantized_class
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def remove_subcommand(name)
        self.recognised_subcommands.delete_if do |sc|
          if sc.is_called?(name)
            logger.info "subcommand #{name} (#{sc.subcommand_class}) was removed."
            true
          else
            false
          end
        end
      end

      def subcommand!(name, description, subcommand_class = self, &block)
        remove_subcommand(name)
        subcommand(name, description, subcommand_class, &block)
        logger.info "subcommand #{name} (#{subcommand_class}) was created."
      end

      def subcommand(name, description, subcommand_class = self, &block)
        existing = find_subcommand(name)
        if existing
          raise HammerCLI::CommandConflict, _("can't replace subcommand %<name>s (%<existing_class>s) with %<name>s (%<new_class>s)") % {
            :name => name,
            :existing_class => existing.subcommand_class,
            :new_class => subcommand_class
          }
        end
        super
      end

      def lazy_subcommand(name, description, subcommand_class, path, hidden = false)
        # call original subcommand to ensure command's parameters are set correctly
        # (hammer command SUBCOMMAND [ARGS] ...)
        subcommand(name, description, Class)
        # replace last subcommand definition with correct lazy-loaded one
        recognised_subcommands[-1] = LazyDefinition.new(name, description, subcommand_class, path, hidden)
      end

      def lazy_subcommand!(name, description, subcommand_class, path, hidden = false)
        remove_subcommand(name)
        self.lazy_subcommand(name, description, subcommand_class, path, hidden)
        logger.info "subcommand #{name} (#{subcommand_class}) was created."
      end

    end

  end
end
