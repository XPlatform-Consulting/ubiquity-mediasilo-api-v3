require 'ubiquity/mediasilo/api/v3/http_client'
require 'ubiquity/mediasilo/api/v3/client/requests'

class Ubiquity::MediaSilo::API::V3::Client

  attr_accessor :logger

  attr_accessor :http_client, :request, :response

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

  def error_message
    ''
  end

  def success?
    _code = http_client.response.code
    _code and _code.start_with?('2')
  end

  def process_request(request_class, args, options = { })
    @request = request_class.new(args, options.merge(:client => self))
    options[:query] = request.query
    @response = case request_class::HTTP_METHOD
                  when :delete
                    http_client.delete(request.path, options)
                  when :put
                    http_client.put(request.path, request.body, options)
                  when :post
                    http_client.post(request.path, request.body, options)
                  when :get
                    http_client.get(request.path, request.query, options)
                end
  end

  def asset_copy_to_folder(args = { }, options = { })
    process_request(Requests::AssetCopyToFolder, args, options)
  end

  def asset_copy_to_project(args = { }, options = { })
    process_request(Requests::AssetCopyToProject, args, options)
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

  def assets_get(args = { }, options = { })
    query = options[:query] || { :type => '{"in":"video,image,document,archive,audio"}' }
    @response = http_client.get('/assets', query)
  end

  # @note This will get all assets for a project, even if they are in a folder
  # @param [Hash] args
  # @option args [String] project_id The Id of the project to get the assets for
  # @return [Array]
  def assets_get_by_project_id(args = { }, options = { })
    project_id = case args
                   when String; args
                   when Hash; args[:id] || args[:project_id]
                 end
    @response = http_client.get('/projects/%s/assets' % project_id)
  end

  def asset_move_to_folder(args = { }, options = { })
    process_request(Requests::AssetMoveToFolder, args, options)
  end

  def asset_move_to_project(args = { }, options = { })
    process_request(Requests::AssetMoveToProject, args, options)
  end

  def folder_create(args = { })
    @response = http_client.post('/folders', args)
  end

  def folder_delete(folder_id)
    folder_id = folder_id[:id] if folder_id.is_a?(Hash)
    @response = http_client.delete('/folders/%s' % folder_id)
  end

  def folders_get_by_parent_id(args = { })
    folder_id = case args
                   when String; args
                   when Hash; args[:id] || args[:parent_id]
                 end
    @response = http_client.get('/folders/%s/subfolders' % folder_id)
  end

  def folders_get_by_project_id(args = { })
    project_id = case args
                   when String; args
                   when Hash; args[:id] || args[:project_id]
                 end
    @response = http_client.get('/projects/%s/folders' % project_id)
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
