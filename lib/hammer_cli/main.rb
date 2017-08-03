require 'highline/import'

module HammerCLI

  class MainCommand < AbstractCommand

    option "--version", :flag, _("show version") do
      puts "hammer (%s)" % HammerCLI.version
      HammerCLI::Modules.names.each do |m|
        module_version = HammerCLI::Modules.find_by_name(m).version rescue _("unknown version")
        puts " * #{m} (#{module_version})"
      end
      exit(HammerCLI::EX_OK)
    end

    option "--autocomplete", "LINE", _("Get list of possible endings"), :hidden => true do |line|
      # get rid of word 'hammer' on the line
      line = line.to_s.gsub(/^\S+/, '')

      completer = Completer.new(HammerCLI::MainCommand)
      puts completer.complete(line).join(" ")
      exit(HammerCLI::EX_OK)
    end

    def option_csv=(csv)
      context[:adapter] = :csv
    end

  end

end


