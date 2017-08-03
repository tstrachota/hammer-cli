require 'hammer_cli/options/normalizers'

module HammerCLI
  module Options
    class GlobalOptions < Clamp::Command
      def self.define_global_options(base, hidden=false)
        base.option ["-v", "--verbose"], :flag, _("Be verbose"), :hidden => hidden
        base.option ["-d", "--debug"], :flag, _("Show debugging output"), :hidden => hidden
        base.option ["-r", "--reload-cache"], :flag, _("Force reload of Apipie cache"), :hidden => hidden

        base.option ["-c", "--config"], "CFG_FILE", _("Path to custom config file"), :hidden => hidden

        base.option ["-u", "--username"], "USERNAME", _("Username to access the remote system"), :hidden => hidden
        base.option ["-p", "--password"], "PASSWORD", _("Password to access the remote system"), :hidden => hidden
        base.option ["-s", "--server"], "SERVER", _("Remote system address"), :hidden => hidden
        base.option ["--verify-ssl"], "VERIFY_SSL", _("Configure SSL verification of remote system"), :hidden => hidden do |value|
          bool_normalizer = HammerCLI::Options::Normalizers::Bool.new
          bool_normalizer.format(value)
        end
        base.option ["--ssl-ca-file"], "CA_FILE", _("Configure the file containing the CA certificates"), :hidden => hidden
        base.option ["--ssl-ca-path"], "CA_PATH", _("Configure the directory containing the CA certificates"), :hidden => hidden
        base.option ["--ssl-client-cert"], "CERT_FILE", _("Configure the client's public certificate"), :hidden => hidden
        base.option ["--ssl-client-key"], "KEY_FILE", _("Configure the client's private key"), :hidden => hidden
        base.option ["--ssl-with-basic-auth"], :flag, _("Use standard authentication in addition to client certificate authentication"), :hidden => hidden
        base.option ["--fetch-ca-cert"], "SERVER", _("Fetch CA certificate from server and exit"), :hidden => hidden

        base.option ["--show-ids"], :flag, _("Show ids of associated resources"), :hidden => hidden

        base.option ["--interactive"], "INTERACTIVE", _("Explicitly turn interactive mode on/off"), :hidden => hidden do |value|
          bool_normalizer = HammerCLI::Options::Normalizers::Bool.new
          bool_normalizer.format(value)
        end
        base.option ["--csv"], :flag, _("Output as CSV (same as --output=csv)"), :hidden => hidden
        base.option ["--output"], "ADAPTER", _("Set output format. One of"), :hidden => hidden
        base.option ["--csv-separator"], "SEPARATOR", _("Character to separate the values"), :hidden => hidden
      end

      define_global_options(self)

      def self.parser
        preparser = self.new('', {})
        begin
          preparser.parse(ARGV)
        rescue
        end
        preparser
      end

      def init_context(new_context)
        new_context[:show_ids] ||= self.show_ids?
        new_context[:adapter] ||= self.output
        new_context[:adapter] ||= :csv if self.csv?
        new_context[:csv_separator] ||= self.csv_separator
        new_context
      end

      def setting_params
        {
          :username => self.username,
          :password => self.password,
          :host => self.server,
          :interactive => self.interactive,
          :verbose => self.verbose? || self.debug?,
          :reload_cache => self.reload_cache?,
          :verify_ssl => self.verify_ssl,
          :ssl_ca_file => self.ssl_ca_file,
          :ssl_ca_path => self.ssl_ca_path,
          :ssl_client_cert => self.ssl_client_cert,
          :ssl_client_key => self.ssl_client_key,
          :ssl_with_basic_auth => self.ssl_with_basic_auth?
        }
      end

      private

      def set_options_from_command_line
        while remaining_arguments.first
          switch = remaining_arguments.shift
          if switch.start_with?("-")
            break if switch == "--"

            case switch
            when /\A(-\w)(.+)\z/m # combined short options
              switch = Regexp.last_match(1)
              if find_option(switch).flag?
                remaining_arguments.unshift("-" + Regexp.last_match(2))
              else
                remaining_arguments.unshift(Regexp.last_match(2))
              end
            when /\A(--[^=]+)=(.*)\z/m
              switch = Regexp.last_match(1)
              remaining_arguments.unshift(Regexp.last_match(2))
            end

            begin
              option = find_option(switch)
              value = option.extract_value(switch, remaining_arguments)
              option.of(self).take(value)
            rescue
              # we skip unknown options and continue scanning
              next
            end
          end
        end
      end
    end
  end
end
