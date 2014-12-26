require 'cgi'

module Ubiquity
  module MediaSilo
    class API
      module V3
        class Client
          module Requests
            class BaseRequest

              HTTP_METHOD = :get
              HTTP_PATH = ''
              HTTP_SUCCESS_CODE = 200

              PARAMETERS = [ ]

              attr_accessor :arguments, :options, :missing_required_arguments

              attr_writer :parameters, :path, :body, :query

              def initialize(args = { }, options = { })
                @options = options.dup
                @client = options[:client]
                @missing_required_arguments = [ ]
                @arguments = process_parameters(parameters, args)
                post_process_arguments unless options.fetch(:skip_post_process_arguments, false)
              end

              def normalize_parameter_name(name)
                name.respond_to?(:to_s) ? name.to_s.gsub('_', '').downcase : name
              end

              def process_parameters(params, args, options = { })
                args = normalize_argument_hash_keys(args)
                processed_params = { }
                params.each do |k|
                  if k.is_a?(Hash) then
                    proper_parameter_name = k[:name]
                    param_name = normalize_parameter_name(proper_parameter_name)
                    has_key = args.has_key?(param_name)
                    param_name = ( (k[:aliases] || [ ]).map { |a| a.to_s }.find { |a| has_key = args.has_key?(a) } || param_name ) unless has_key
                    unless has_key or k.has_key?(:default_value)
                      @missing_required_arguments << proper_parameter_name if k[:required]
                      next
                    end
                    value = has_key ? args[param_name] : k[:default_value]
                  else
                    proper_parameter_name = k
                    param_name =  normalize_parameter_name(proper_parameter_name)
                    next unless args.has_key?(param_name)
                    value = args[param_name]
                  end
                  processed_params[proper_parameter_name] = value
                end
                processed_params
              end

              def normalize_argument_hash_keys(hash)
                return hash unless hash.is_a?(Hash)
                Hash[ hash.dup.map { |k,v| [ normalize_parameter_name(k), v ] } ]
              end

              def post_process_arguments
                # TO BE IMPLEMENTED IN CHILD CLASS
              end

              def parameters
                @parameters ||= self.class::PARAMETERS.dup
              end

              def path
                eval(%("#{self.class::HTTP_PATH}"))
              end

              def body
                arguments
              end

              def query
                nil
              end

            end
          end
        end
      end
    end
  end
end
