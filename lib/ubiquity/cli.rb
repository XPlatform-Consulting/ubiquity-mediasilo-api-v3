require 'optparse'

module Ubiquity

  class CLI

    def self.define_parameters
      # To be implemented by the child class
      argument_parser.on_tail('-h', '--help', 'Display this message.') { puts help; exit }
    end

    def initialize(args = self.class.parse_arguments)
      # To be implemented by the child class
    end

    def self.default_options_file_path
      File.expand_path(File.basename($0, '.*'), '~/.options')
    end

    def self.default_arguments
      @default_arguments ||= {
          :options_file_path => default_options_file_path,
      }
    end

    def self.help_usage_default
      "  #{executable_name} -h | --help"
    end

    def self.help_usage
      # To be implemented by the child class
      help_usage_default
    end

    def self.help_usage_append(string = '')
      usage_string = "\n    #{executable_name} #{string}"
      @help_usage << usage_string unless (@help_usage ||= help_usage_default).include?(usage_string)
    end

    def self.help
      @help_usage ||= help_usage_default
      argument_parser.banner = <<-BANNER
Usage:
  #{help_usage}

Options:
      BANNER
      argument_parser
    end

    ## Methods below this line should not need to be implemented by the child class


    class << self
      attr_writer :argument_parser,
                  :help_usage,
                  :default_arguments, :arguments, :arguments_from_command_line, :arguments_from_options_file
    end

    def self.argument_parser(options = { })
      return @argument_parser if @argument_parser and !options[:force_new]
      @argument_parser = OptionParser.new
      arguments and define_parameters if options.fetch(:define_parameters, true)
      @argument_parser
    end

    def self.arguments
      @arguments ||= begin
        default_arguments.dup
      end
    end

    def self.arguments_from_command_line(array_of_arguments = ARGV)
      @arguments_from_command_line ||= begin
        arguments_before = arguments.dup
        arguments.clear

        argument_parser.parse!(array_of_arguments.dup)
        _arguments_from_options_file = arguments.dup
        @arguments = arguments_before
        _arguments_from_options_file
      end
    end

    def self.arguments_from_options_file(options_file_path = arguments[:options_file_path])
      @arguments_from_options_file ||= begin
        arguments_before = arguments.dup
        arguments.clear

        argument_parser.load(options_file_path)
        _arguments_from_options_file = arguments.dup
        @arguments = arguments_before
        _arguments_from_options_file
      end
    end

    def self.parse_arguments
      argument_parser
      @arguments = default_arguments.merge(arguments_from_options_file).merge(arguments_from_command_line)
    end

    def self.clear_cached_arguments
      @arguments_from_command_line = nil
      @arguments_from_options_file = nil
      @arguments = nil
      @default_arguments = nil
      argument_parser(:force_new => true)
      true
    end

    def self.executable_name
      @executable_name ||= File.basename($0)
    end

    def self.run(args = nil, init_options = { }, run_options = { })
      args ||= parse_arguments
      new(args, init_options).run(args, run_options)
    end

    # CLI
  end

  # Ubiquity
end
