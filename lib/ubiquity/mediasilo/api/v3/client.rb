require 'ubiquity/mediasilo/api/v3/http_client'
require 'ubiquity/mediasilo/api/v3/client/requests'

class Ubiquity::MediaSilo::API::V3::Client

  attr_accessor :logger

  attr_accessor :http_client, :response

  def initialize(args = { })
    initialize_logger(args)
    initialize_http_client(args)
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

  def initialize_http_client(args = { })
    @http_client = Ubiquity::MediaSilo::API::V3::HTTPClient.new(args)
  end

  def process_request(request_class, args, options = { })
    puts request_class
    _request = request_class.new(args, options.merge(:client => self))
    options[:query] = _request.query
    @response = case request_class::HTTP_METHOD
                  when :delete
                    http_client.delete(_request.path, options)
                  when :put
                    http_client.put(_request.path, _request.body, options)
                  when :post
                    http_client.post(_request.path, _request.body, options)
                  when :get
                    http_client.get(_request.path, _request.query, options)
                end
  end

  def asset_create(args = { }, options = { })
    # args_out = Requests::AssetCreate.new(args, options).arguments
    # @response = http_client.post('/assets', args_out)

    process_request(Requests::AssetCreate, args, options)
  end

  def asset_delete_by_id(args = { }, options = { })
    # asset_id = asset_id[:id] if asset_id.is_a?(Hash)
    # @response = http_client.delete('/assets/%s' % asset_id)

    args = { :assetId => args } if args.is_a?(String)
    # _request = Requests::AssetDelete.new(args, options)
    # @response = http_client.delete(_request.path)
    process_request(Requests::AssetDelete, args, options)
  end
  alias :asset_delete :asset_delete_by_id

  def asset_get_by_id(args = { }, options = { })
    process_request(Requests::AssetGetById, args, options)
  end

  def assets_get(args = { })
    @response = http_client.get('/assets')
  end


  def assets_get_by_project_id(project_id)
    project_id = project_id[:id] || project_id[:project_id] if project_id.is_a?(Hash)
    @response = http_client.get('/projects/%s/assets' % project_id)
  end

  def folder_create(args = { })
    @response = http_client.post('/folders', args)
  end

  def folder_delete(folder_id)
    folder_id = folder_id[:id] if folder_id.is_a?(Hash)
    @response = http_client.delete('/folders/%s' % folder_id)
  end

  def project_create(args = { })
    @response = http_client.post('/projects', args)
  end

  def project_delete(project_id)
    project_id = project_id[:id] if project_id.is_a?(Hash)
    @response = http_client.delete('/projects/%s' % project_id)
  end

  def project_get_by_id(project_id)
    project_id = project_id[:id] if project_id.is_a?(Hash)
    @response = http_client.get('/projects/%s' % project_id)
  end

  def projects_get
    @response = http_client.get('/projects')
  end

end
