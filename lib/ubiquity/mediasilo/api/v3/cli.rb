require 'ubiquity/cli'

require 'ubiquity/mediasilo/api/v3/client'

class Ubiquity::MediaSilo::API::V3::CLI < Ubiquity::CLI

  def self.help_usage
    help_usage_append '--hostname <HOSTNAME> --username <USERNAME> --password <PASSWORD> --method-name <METHODNAME> --method-arguments <JSON>'
  end

  def self.define_parameters
    argument_parser.on('--hostname HOSTNAME', 'The account hostname to authenticate with.') { |v| arguments[:hostname] = v }
    argument_parser.on('--username USERNAME', 'The account username to authenticate with.') { |v| arguments[:username] = v }
    argument_parser.on('--password PASSWORD', 'The account password to authenticate with.') { |v| arguments[:password] = v }

    argument_parser.on('--method-name METHODNAME', 'The name of the method to call.') { |v| arguments[:method_name] = v }
    argument_parser.on('--method-arguments JSON', 'The arguments to pass when calling the method.') { |v| arguments[:method_arguments] = v }
    argument_parser.on('--pretty-print', 'Will format the output to be more human readable.') { |v| arguments[:pretty_print] = v }

    argument_parser.on('--[no-]options-file [FILENAME]', 'Path to a file which contains default command line arguments.', "\tdefault: #{arguments[:options_file_path]}" ) { |v| arguments[:options_file_path] = v}
    argument_parser.on_tail('-h', '--help', 'Display this message.') { puts help; exit }
  end

  attr_accessor :logger, :api

  def initialize(args = self.class.arguments, options = { })
    @initial_args = args.dup
    initialize_logger(args)
    initialize_api(args)
  end

  # @param [Hash] args
  # @option args [Logger]     :logger A logger to be used
  # @option args [IO, String] :log_to An IO device or file to log to
  # @option args [Integer]    :log_level (Logger::DEBUG) The logging level to be set to the logger
  def initialize_logger(args = { })
    @logger = args[:logger] ||= Logger.new(args[:log_to] ||= STDERR)
    @logger.level = (log_level = args[:log_level]) ? log_level : Logger::WARN
    args[:logger] = @logger
    args[:log_level] ||= @logger.level
    @logger
  end

  def initialize_api(args = { })
    @api = Ubiquity::MediaSilo::API::V3::Client.new(args.merge(:parse_response => false))
  end

  def send(method_name, method_arguments, params = {})
    method_name = method_name.to_sym
    logger.debug { "Executing Method: #{method_name}" }

    send_arguments = [ method_name ]

    if method_arguments
      method_arguments = JSON.parse(method_arguments, :symbolize_names => true) if method_arguments.is_a?(String) and method_arguments.start_with?('{', '[')
      send_arguments << method_arguments
    end

    response = api.__send__(*send_arguments)

    # if aa.response.code.to_i.between?(500,599)
    #   puts aa.parsed_response
    #   exit
    # end
    #
    # if ResponseHandler.respond_to?(method_name)
    #   ResponseHandler.aa = aa
    #   ResponseHandler.response = response
    #   response = ResponseHandler.__send__(*send_arguments)
    # end

    if params[:pretty_print]
      if response.is_a?(String) and response.lstrip.start_with?('{', '[')
        puts JSON.pretty_generate(JSON.parse(response))
      else
        pp response
      end
    else
      response = JSON.generate(response) if response.is_a?(Hash) or response.is_a?(Array)
      puts response
    end
    # send
  end

  def run(args = self.class.arguments, options = { })
    #puts "#{__FILE__}:#{__LINE__}:#{args}"
    method_name = args[:method_name]
    send(method_name, args[:method_arguments], :pretty_print => args[:pretty_print]) if method_name

    self
  end

end
def cli; @cli ||= Ubiquity::MediaSilo::API::V3::CLI end