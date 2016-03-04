require 'fast_gettext'
require 'locale'

module HammerCLI
  module I18n

    TEXT_DOMAIN = 'hammer-cli'

    # include this module to see translations highlighted
    module Debug
      DL = '>'
      DR = '<'

      # slightly modified copy of fast_gettext _ method
      def _(key)
        _wrap { FastGettext::Translation._(key) }
      end

      # slightly modified copy of fast_gettext n_ method
      def n_(*keys)
        _wrap { FastGettext::Translation.n_(*keys) }
      end

      # slightly modified copy of fast_gettext s_ method
      def s_(key, separator=nil, &block)
        _wrap { FastGettext::Translation.s_(key, separator, &block) }
      end

      # slightly modified copy of fast_gettext ns_ method
      def ns_(*args, &block)
        _wrap { FastGettext::Translation.ns_(*args, &block) }
      end

      def _wrap(&block)
        result = yield
        DL + result + DR unless result.nil?
      end
    end

    class AbstractLocaleDomain
      def available_locales
        Dir.glob(locale_dir+'/*').select { |f| File.directory? f }.map { |f| File.basename(f) }
      end

      def translated_files
        []
      end

      def type
        :mo
      end

      def available?
        Dir[File.join(locale_dir, '**', "#{domain_name}.#{type}")].any?
      end

      attr_reader :locale_dir, :domain_name
    end


    class LocaleDomain < AbstractLocaleDomain
      def translated_files
        Dir.glob(File.join(File.dirname(__FILE__), '../**/*.rb'))
      end

      def locale_dir
        File.join(File.dirname(__FILE__), '../../locale')
      end

      def domain_name
        'hammer-cli'
      end
    end

    class SystemLocaleDomain < LocaleDomain
      def locale_dir
        '/usr/share/locale'
      end
    end

    class LazyMoFile < FastGettext::MoFile
      attr_reader :data

      def initialize(file)
        @filename = file
      end

      def load_data(file)
        if file.is_a? FastGettext::GetText::MOFile
          @data = file
        else
          @data = FastGettext::GetText::MOFile.open(file, "UTF-8")
        end
        make_singular_and_plural_available
      end

      def [](key)
        load_data(@filename) if @data.nil?
        @data[key]
      end

      def data
        load_data(@filename) if @data.nil?
        @data
      end

      protected

      def current_translations
        @files[FastGettext.locale] ||= MoFile.empty
      end
    end

    require 'fast_gettext/translation_repository/mo'

    class LazyMoRepository < FastGettext::TranslationRepository::Mo
      def path
        @options[:path]
      end

      protected
      def find_and_store_files(name, options)
        find_files_in_locale_folders(File.join('LC_MESSAGES',"#{name}.mo"), options[:path]) do |locale,file|
          LazyMoFile.new(file)
        end
      end
    end

    class UnifiedRepository < FastGettext::TranslationRepository::Base
      def initialize(name)
        clear
        super(name)
      end

      def available_locales
        @repositories.map { |r| r.available_locales }.flatten.uniq
      end

      def pluralisation_rule
        @repositories.each do |r|
          result = r.pluralisation_rule and return result
        end
        nil
      end

      def reload
        @data = {}
        @repositories.each do |r|
          load_repo(r)
        end
        super
      end

      def add_repo(r)
        @repositories << r
        load_repo(r)
      end

      def [](key)
        @data[key]
      end

      def clear
        @repositories = []
        @data = {}
      end

      protected

      def load_repo(r)
        r.reload
        translations = r.send('current_translations')
        if translations.respond_to?(:data)
          @data = translations.data.merge(@data)
        end
      end
    end

    def self.locale
      lang_variant = Locale.current.to_simple.to_str
      lang = lang_variant.gsub(/_.*/, "")

      hammer_domain = HammerCLI::I18n::LocaleDomain.new
      if hammer_domain.available_locales.include? lang_variant
        lang_variant
      else
        lang
      end
    end

    def self.domains
      @domains ||= []
      @domains
    end

    def self.add_domain(domain)
      if domain.available?
        domains << domain
        translation_repository.add_repo(build_repository(domain))
      end
    end

    def self.build_repository(domain)
      if domain.type.to_s == 'mo'
        LazyMoRepository.new(domain.domain_name, :path => domain.locale_dir, :report_warning => false)
      else
        FastGettext::TranslationRepository.build(domain.domain_name, :path => domain.locale_dir, :type => domain.type, :report_warning => false)
      end
    end

    def self.clear
      translation_repository.clear
      domains.clear
    end

    def self.translation_repository
      FastGettext.translation_repositories[HammerCLI::I18n::TEXT_DOMAIN] ||= HammerCLI::I18n::UnifiedRepository.new(HammerCLI::I18n::TEXT_DOMAIN)
    end

    Encoding.default_external='UTF-8' if defined? Encoding
    FastGettext.locale = locale
    FastGettext.text_domain = HammerCLI::I18n::TEXT_DOMAIN
  end
end

include FastGettext::Translation


domain = [HammerCLI::I18n::LocaleDomain.new, HammerCLI::I18n::SystemLocaleDomain.new].find { |d| d.available? }
HammerCLI::I18n.add_domain(domain) if domain

