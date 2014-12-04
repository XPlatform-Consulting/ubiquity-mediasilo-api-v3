require 'cgi'
require 'json'
require 'logger'
require 'net/http'
require 'net/https'

require 'ubiquity/mediasilo/api/v3'

module Ubiquity
  module MediaSilo
    module API
      module V3

        class HTTPClient

          class CaseSensitiveHeaderKey < String
            def downcase; self end
            def capitalize; self end
          end

          attr_accessor :logger, :http, :http_host_address, :http_host_port, :base_uri
          attr_accessor :hostname, :username, :password

          attr_accessor :default_request_headers,
                        :authorization_header_name, :authorization_header_value,
                        :host_context_header_name, :host_context_header_value

          attr_accessor :log_request_body, :log_response_body, :log_pretty_print_body

          attr_accessor :request, :response

          DEFAULT_HTTP_HOST_ADDRESS = 'api.mediasilo.com'
          DEFAULT_HTTP_HOST_PORT = 443

          def initialize(args = { })
            args = args.dup
            initialize_logger(args)
            initialize_http(args)

            @hostname = args[:hostname] || ''
            @username = args[:username] || ''
            @password = args[:password] || ''

            @base_uri = args[:base_uri] || "http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}/v3/"

            @user_agent_default = "#{@hostname}:#{@username} Ruby SDK Version #{Ubiquity::MediaSilo::API::V3::VERSION}"

            @authorization_header_name ||= CaseSensitiveHeaderKey.new('Authorization')
            @authorization_header_value ||= 'Basic ' + ["#{username}:#{password}"].pack('m').delete("\r\n")

            @host_context_header_name = CaseSensitiveHeaderKey.new('MediaSiloHostContext')
            @host_context_header_value = hostname.downcase

            @default_request_headers = {
              'Content-Type' => 'application/json; charset=utf-8',
              'Accept' => 'application/json',
              host_context_header_name => host_context_header_value,
              authorization_header_name => authorization_header_value,
            }

            @log_request_body = args.fetch(:log_request_body, true)
            @log_response_body = args.fetch(:log_response_body, true)
            @log_pretty_print_body = args.fetch(:log_pretty_print_body, true)

            @parse_response = args.fetch(:parse_response, true)
          end

          def initialize_logger(args = { })
            @logger = args[:logger] ||= Logger.new(args[:log_to] || STDOUT)
            log_level = args[:log_level]
            if log_level
              @logger.level = log_level
              args[:logger] = @logger
            end
            @logger
          end

          def initialize_http(args = { })
            @http_host_address = args[:http_host_address] ||= DEFAULT_HTTP_HOST_ADDRESS
            @http_host_port = args[:http_host_port] ||= DEFAULT_HTTP_HOST_PORT
            @http = Net::HTTP.new(http_host_address, http_host_port)
            http.use_ssl = true

            # TODO Add SSL Patch
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            http
          end

          # Formats a HTTPRequest or HTTPResponse body for log output.
          # @param [HTTPRequest|HTTPResponse] obj
          # @return [String]
          def format_body_for_log_output(obj)
            #obj.body.inspect
            output = ''
            if obj.content_type == 'application/json'
              if @log_pretty_print_body
                _body = obj.body
                output << "\n"
                output << JSON.pretty_generate(JSON.parse(_body)) rescue _body
                return output
              else
                return obj.body
              end
            else
              return obj.body.inspect
            end
          end

          def send_request(request)
            @request = request
            logger.debug { %(REQUEST: #{request.method} http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}#{request.path} HEADERS: #{request.to_hash.inspect} #{log_request_body and request.request_body_permitted? ? "BODY: #{format_body_for_log_output(request)}" : ''}) }

            @response = http.request(request)
            logger.debug { %(RESPONSE: #{response.inspect} HEADERS: #{response.to_hash.inspect} #{log_response_body and response.respond_to?(:body) ? "BODY: #{format_body_for_log_output(response)}" : ''}) }

            @parse_response ? response_parsed : response.body
          end

          def response_parsed
            JSON.parse(response.body) rescue response
          end

          def build_uri(path = '', query = { })
            _query = query.is_a?(Hash) ? query.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join('&') : query
            _path = "#{path}#{_query and _query.respond_to?(:empty?) and !_query.empty? ? "?#{_query}" : ''}"
            URI.parse(File.join(base_uri, _path))
          end

          def delete(path, options = { })
            query = options.fetch(:query, { })
            @uri = build_uri(path, query)
            request = Net::HTTP::Delete.new(@uri.request_uri, default_request_headers)
            send_request(request)
          end

          def get(path, query = nil, options = { })
            query ||= options.fetch(:query, { })
            @uri = build_uri(path, query)
            request = Net::HTTP::Get.new(@uri.request_uri, default_request_headers)
            send_request(request)
          end

          def put(path, body, options = { })
            query = options.fetch(:query, { })
            @uri = build_uri(path, query)
            body = JSON.generate(body) unless body.is_a?(String)

            request = Net::HTTP::Put.new(@uri.request_uri, default_request_headers)
            request.body = body
            send_request(request)
          end

          def post(path, body, options = { })
            query = options.fetch(:query, { })
            @uri = build_uri(path, query)
            body = JSON.generate(body) unless body.is_a?(String)

            request = Net::HTTP::Post.new(@uri.request_uri, default_request_headers)
            request.body = body
            send_request(request)
          end

        end

      end
    end
  end
end
