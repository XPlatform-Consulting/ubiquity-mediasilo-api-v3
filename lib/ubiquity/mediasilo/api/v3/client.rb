require 'ubiquity/mediasilo/api/v3/http_client'
require 'ubiquity/mediasilo/api/v3/client/requests'
require 'ubiquity/mediasilo/api/v3/client/paginator'

class Ubiquity::MediaSilo::API::V3::Client

  attr_accessor :logger

  attr_accessor :http_client, :request, :response, :batch_requests, :http_response

  def initialize(args = { })
    initialize_logger(args)
    initialize_http_client(args)

    @batch_mode = false
    @batch_requests = [ ]
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
    response.is_a?(String) ? response.gsub(/<[^>]*>/ui,'') : ''
  end

  def success?
    return request.success? if request.respond_to?(:success?)

    _code = http_client.response.code
    _code and _code.start_with?('2')
  end

  # @param [Requests::BaseRequest] request
  # @param [Hash, nil] options
  # @option options [Boolean] :execute_request (true) Will execute the request
  # @option options [Boolean] :return_request (true) Will return the request instance instead of nil. Only applies if
  #   execute_request is false.
  def process_request(request, options = nil)
    @paginator = nil
    @response = nil
    @request = request
    logger.warn { "Request is Missing Required Arguments: #{request.missing_required_arguments.inspect}" } unless request.missing_required_arguments.empty?

    if batch_mode
      logger.debug { "Adding Request to Batch. #{request.inspect}" }
      @batch_requests << request
      return batch_requests
    end

    if ([:all, 'all'].include?(request.arguments[:_page]))
      request.arguments[:_page] = 1
      include_remaining_pages = true
    else
      include_remaining_pages = false
    end

    request.client = self unless request.client
    options ||= request.options

    return (options.fetch(:return_request, true) ? request : nil) unless options.fetch(:execute_request, true)

    #@response = http_client.call_method(request.http_method, { :path => request.path, :query => request.query, :body => request.body }, options)
    @response = request.execute

    if include_remaining_pages
      return paginator.include_remaining_pages
    end

    @response
  end

  def paginator
    @paginator ||= Paginator.new(self) if @response
  end

  def process_request_using_class(request_class, args = { }, options = { })
    @response = nil
    @request = request_class.new(args, options)
    process_request(request, options)
  end

  # ################################################################################################################## #
  # @!group API Methods

  # @see https://phoenix.readme.io/docs/aspera-file-download
  def aspera_file_download_ticket_create(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'aspera/download/#{path_arguments[:asset_id]}/#{path_arguments[:target]}',
        :http_method => :post,
        :parameters => [
          { :name => :asset_id, :send_in => :path },
          { :name => :target, :send_in => :path } # Either 'source' or 'proxy'
        ]
      }
    )
    response = process_request(_request, options)
    response
  end

  # @see https://phoenix.readme.io/docs/aspera-file-upload
  def aspera_file_upload_ticket_create(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'aspera/upload',
        :http_method => :post,
        :parameters => [
          { :name => :fileName, :send_in => :body }
        ]
      }
    )

    response = process_request(_request, options)
    response
  end

  def asset_copy_to_folder(args = { }, options = { })
    process_request_using_class(Requests::AssetCopyToFolder, args, options)
  end

  def asset_copy_to_project(args = { }, options = { })
    process_request_using_class(Requests::AssetCopyToProject, args, options)
  end

  # @see http://docs.mediasilo.com/v3.0/docs/create-asset
  def asset_create(args = { }, options = { })
    # args_out = Requests::AssetCreate.new(args, options).arguments
    # @response = http_client.post('/assets', args_out)
    process_request_using_class(Requests::AssetCreate, args, options)
  end

  def asset_delete_by_id(args = { }, options = { })
    # asset_id = asset_id[:id] if asset_id.is_a?(Hash)
    # @response = http_client.delete('/assets/%s' % asset_id)

    args = { :assetId => args } if args.is_a?(String)
    # _request = Requests::AssetDelete.new(args, options)
    # @response = http_client.delete(_request.path)
    process_request_using_class(Requests::AssetDelete, args, options)
  end
  alias :asset_delete :asset_delete_by_id

  # @see http://docs.mediasilo.com/v3.0/docs/edit-asset
  def asset_edit(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :put,
        :http_path => 'assets/#{path_arguments[:asset_id]}',
        :http_success_code => 204,
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :title, :send_in => :body },
          { :name => :description, :send_in => :body }
        ]
      }
    )
    process_request(_request, options)
  end

  # @see http://docs.mediasilo.com/v3.0/docs/asset-detail
  def asset_get_by_id(args = { }, options = { })
    args = { :asset_id => args } if args.is_a?(String)
    process_request_using_class(Requests::AssetGetById, args, options)
  end

  # @see http://docs.mediasilo.com/v3.0/docs/all-assets
  def assets_get(args = { }, options = { })
    # query = options[:query] || { :type => '{"in":"video,image,document,archive,audio"}' }
    # @response = http_client.get('/assets', query)
    _response = process_request_using_class(Requests::AssetsGet, args, options)
    _response = [ ] unless _response.is_a?(Array)
    _response
  end

  # @note This will get all assets for a folder
  # @param [Hash] args
  # @option args [String] folder_id The Id of the folder to get the assets for
  # @return [Array]
  # @see http://docs.mediasilo.com/v3.0/docs/assets-in-folder
  def assets_get_by_folder_id(args = { }, options = { })
    args = { :id => args } if args.is_a?(String)

    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'folders/#{path_arguments[:folder_id]}/assets',
        :parameters => [
          { :name => :folder_id, :aliases => [ :id ], :send_in => :path, :required => true },
          {
            :name => :type,
            # Received a 500 Request Failed error if 'type' was not set so we default it
            # :default_value => '{"in":"video,image,document,archive,audio"}',
            :send_in => :query
          },
          { :name => :_page, :aliases => [ :page ], :send_in => :query },
          { :name => :_pageSize, :aliases => [ :page_size ], :send_in => :query },
          { :name => :_sort, :aliases => [ :sort ], :send_in => :query },
          { :name => :_sortBy, :aliases => [ :sort_by ], :send_in => :query }
        ]
      }
    )
    response = process_request(_request, options)
    response
  end


  # @note This will get all assets for a project
  # @param [Hash] args
  # @option args [String] project_id The Id of the project to get the assets for
  # @return [Array]
  # @see http://docs.mediasilo.com/v3.0/docs/assets-in-project
  def assets_get_by_project_id(args = { }, options = { })
    args = { :id => args } if args.is_a?(String)

    # return_all_results = options.fetch(:return_all_results, false)

    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'projects/#{path_arguments[:project_id]}/assets',
        :parameters => [
          { :name => :project_id, :aliases => [ :id ], :send_in => :path, :required => true },
          {
            :name => :type,
            # Received a 500 Request Failed error if 'type' was not set so we default it
            # :default_value => '{"in":"video,image,document,archive,audio"}',
            :send_in => :query
          },
          { :name => :_page, :aliases => [ :page ], :send_in => :query },
          { :name => :_pageSize, :aliases => [ :page_size ], :send_in => :query },
          { :name => :_sort, :aliases => [ :sort ], :send_in => :query },
          { :name => :_sortBy, :aliases => [ :sort_by ], :send_in => :query }
        ]
      }
    )
    response = process_request(_request, args)

    # response.delete_if { |asset| asset['folderId'] } if response.is_a?(Array) &&!return_all_results

    response
  end

  def asset_move_to_folder(args = { }, options = { })
    process_request_using_class(Requests::AssetMoveToFolder, args, options)
  end

  def asset_move_to_project(args = { }, options = { })
    process_request_using_class(Requests::AssetMoveToProject, args, options)
  end

  # @see http://docs.mediasilo.com/v3.0/docs/add-tag-to-asset
  def asset_tag_add(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :post,
        :http_success_code => '204',
        :http_path => 'assets/#{path_arguments[:asset_id]}/tags',
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :tags, :aliases => [ :tag ], :send_in => :body },
        ]
      }
    )
    _tags = _request.arguments[:tags]
    _request.arguments[:tags] = [*_tags] unless _tags.is_a?(Array)

    process_request(_request, options)
  end
  alias :asset_tags_add :asset_tag_add
  alias :asset_add_tag :asset_tag_add

  def asset_tag_delete(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :delete,
        :http_success_code => '204',
        :http_path => 'assets/#{path_arguments[:asset_id]}/tags/#{path_arguments[:tag]}',
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :tag, :send_in => :path },
        ]
      }
    )
    process_request(_request, options)
  end
  alias :asset_tag_remove :asset_tag_delete

  def asset_upload_ticket_create(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :post,
        :http_path => 'assets/upload',
        :parameters => [
          { :name => :fileName, :send_in => :body }
        ]
      }
    )
    process_request(_request, options)
  end

  def asset_upload(args = { }, options = { })

  end

  # This endpoint is available to admins on any user id, or the current user on their own user id. It returns
  # immediately, and watermarking runs in the background. To check whether the watermarking is done, you need to get
  # the ‘proxy’ derivative our of the asset response model and check the ‘progress’ key. Be careful, because there are
  # also ‘progress’ values at the base of the asset response model as well as in the ‘preroll’ derivative. You want
  # the ‘proxy’ one. When that hits 100, the video is ready to play back.
  #
  # @param [Hash] args ({ })
  # @option args [String] :asset_id
  # @option args [String] :user_id
  def asset_watermark_trigger(args = { }, options = { })
    _request = Requests::BaseRequest.new(
        args,
        {
            :http_method => :post,
            :http_success_code => '204',
            :http_path => 'assets/#{path_arguments[:asset_id]}/watermark/#{path_arguments[:user_id]}',
            :parameters => [
                { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
                { :name => :user_id, :send_in => :path },
            ]
        }
    )
    process_request(_request, options)
  end

  # Executes the queued requests as a batch
  # @param [Array] requests (@batch_requests)
  # @param [Hash] options
  def batch_execute(requests = nil, options = { })
    if block_given?
      @batch_mode = true
      yield
      _requests = @batch_requests + (requests || [ ])
    else
      _requests = requests.nil? ? @batch_requests.dup : requests.dup
    end
    @batch_mode = false
    return [ ] if _requests.empty?
    _requests.map! { |req| req.respond_to?(:to_batchable_request) ? req.to_batchable_request : req }
    _response = [ ]

    if requests.nil? and options.fetch(:clear_requests, true)
      @batch_requests = [ ]
    else
      requests = [ ]
    end

    # @request_history.concat(_requests)
    _requests.each_slice(50) do |_req|
      process_request_using_class(Requests::Batch, { :requests => _req }, options)
      _response << @response
    end
    @response = _response
  end

  # Sets the batch mode
  # @param [True,False] value
  def batch_mode=(value, options = { })
    @batch_mode = value
    @batch_requests = [ ] if value and options.fetch(:clear_requests, true)
    @batch_mode
  end

  # Returns true if the client is currently batching requests
  def batch_mode?
    @batch_mode
  end
  alias :batch_mode :batch_mode?

  def batch_mode_enable
    self.batch_mode = true
  end

  # @see http://docs.mediasilo.com/v3.0/docs/create-folder
  def folder_create(args = { }, options = { })
    # @response = http_client.post('/folders', args)

    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :post,
        :http_path => 'folders',
        :parameters => [
          { :name => :name, :send_in => :body },
          { :name => :projectId, :send_in => :body },
          { :name => :parentId, :default_value => 0, :send_in => :body }
        ]
      }
    )

    # arguments = _request.arguments
    # parent_id = arguments[:parentId]
    #
    # if parent_id && parent_id != 0
    #   logger.debug { 'Unsetting projectId because parentId is set.'  }
    #   arguments.delete(:projectId)
    # end
    #
    # _request.arguments = arguments

    process_request(_request, options)
  end

  def folder_delete(args = { }, options = { })
    # folder_id = folder_id[:id] if folder_id.is_a?(Hash)
    # @response = http_client.delete('/folders/%s' % folder_id)

    args = { :folder_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_method => :delete,
        :http_path => 'folders/#{path_arguments[:folder_id]}',
        :parameters => [
          { :name => :folder_id, :aliases => [ :id ], :send_in => :path }
        ]
      }.merge(options)
    )
    process_request(_request, options)
  end

  def folder_get_by_id(args = { }, options = { })
    args = { :folder_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'folders/#{path_arguments[:folder_id]}',
        :parameters => [
          { :name => :folder_id, :aliases => [ :id ], :send_in => :path }
        ]
      }.merge(options)
    )
    process_request(_request, options)
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

  def metadata_get(args = { }, options = { })
    return_as_hash = options.delete(:return_as_hash) { false }

    args = { :asset_id => args } unless args.is_a?(Hash)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'assets/#{path_arguments[:asset_id]}/metadata',
        :http_success_code => %w(200 404),
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path }
        ]
      }.merge(options)
    )
    _response = process_request(_request, options)

    return (return_as_hash ? {} : []) if _request.client.http_client.response.code == '404'
    return false unless _response.is_a?(Array)

    return Hash[ _response.map { |m| [ m['key'], m['value'] ] } ] if return_as_hash

    _response
  end
  alias :metadata_get_by_asset_id :metadata_get
  alias :metadata_get_by_asset_uuid :metadata_get

  # @see http://docs.mediasilo.com/v3.0/docs/add-metadata
  def metadata_create_or_update(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'assets/#{path_arguments[:asset_id]}/metadata',
        :http_method => :post,
        :http_success_code => 204,
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :key, :send_in => :body},
          { :name => :value, :send_in => :body},
          { :name => :metadata, :send_in => :body},
        ]
      }.merge(options)
    )
    metadata = _request.body_arguments.delete(:metadata) { }
    metadata = metadata.map { |k,v| { 'key' => k, 'value' => v } } if metadata.is_a?(Hash)

    _request.body = metadata.delete_if { |h| v = h['value']; (v.respond_to?(:empty?) && v.empty?) } if metadata
    process_request(_request, options)
  end
  alias :metadata_set :metadata_create_or_update
  alias :metadata_add :metadata_create_or_update
  alias :metadata_create_if_not_exists :metadata_create_or_update

  # @see http://docs.mediasilo.com/v3.0/docs/delete
  def metadata_delete(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'assets/#{path_arguments[:asset_id]}/metadata/#{path_arguments[:metadata_key]}',
        :http_method => :delete,
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :metadata_key, :aliases => [ :key ], :send_in => :path },
        ]
      }.merge(options)
    )
    process_request(_request, options)
  end

  # @see http://docs.mediasilo.com/v3.0/docs/update
  def metadata_replace(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'assets/#{path_arguments[:asset_id]}/metadata',
        :http_method => :put,
        :parameters => [
          { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
          { :name => :key, :send_in => :body },
          { :name => :value, :send_in => :body },
          { :name => :metadata, :send_in => :body },
        ]
      }.merge(options)
    )
    metadata = _request.body_arguments.delete(:metadata) { }
    metadata = metadata.map { |k,v| { 'key' => k, 'value' => v} } if metadata.is_a?(Hash)
    _request.body = metadata if metadata
    process_request(_request, options)
  end
  alias :metadata_mirror :metadata_replace

  # @see http://docs.mediasilo.com/v3.0/docs/create-project
  def project_create(args = { }, options = { })
    args = { :name => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'projects',
        :http_method => :post,
        :parameters => [
          { :name => :name, :send_in => :body, :required => true },
          { :name => :description, :send_in => :body }
        ]
      }.merge(options)
    )
    process_request(_request, options)
  end

  def project_delete(args = { }, options = { })
    args = { :project_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'projects/#{path_arguments[:project_id]}',
        :http_method => :delete,
        :parameters => [
          { :name => :project_id, :aliases => [ :id ], :send_in => :path }
        ]
      }.merge(options)
    )
    process_request(_request, options)
  end

  def project_get_by_id(args = { }, options = { })
    # project_id = project_id[:id] if project_id.is_a?(Hash)
    # @response = http_client.get('/projects/%s' % project_id)

    args = { :project_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'projects/#{path_arguments[:project_id]}',
        :parameters => [
          { :name => :project_id, :aliases => [ :id ], :send_in => :path }
        ]
      }.merge(options)
    )
    process_request(_request, options)
  end

  def projects_get(options = { })
    #@response = http_client.get('/projects')

    _request = Requests::BaseRequest.new(
      { },
      {
        :http_path => 'projects',
        :http_success_code => %w(200 404),
      }.merge(options)
    )
    _response = process_request(_request, options)
    return [] if _request.client.http_client.response.code == '404'

    return _response
  end

  def project_watermark_settings_get(args = { }, options = { })
    args = { :project_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
        args,
        {
            :http_path => 'projects/#{path_arguments[:project_id]}/watermarkSettings',
            :parameters => [
                { :name => :project_id, :aliases => [ :id ], :send_in => :path }
            ]
        }.merge(options)
    )
    process_request(_request, options)
  end

  def project_watermark_settings_set(args = { }, options = { })
    args = { :project_id => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
        args,
        {
            :http_path => 'projects/#{body_arguments[:context]}/watermarkSettings',
            :http_method => 'PUT',
            :parameters => [
                { :name => :context, :aliases => [ :project_id ], :send_in => :body },
                { :name => :id, :send_in => :body },
                { :name => :settings, :send_in => :body },
                { :name => :enabled, :send_in => :body },
            ]
        }.merge(options)
    )
    process_request(_request, options)
  end

  def quicklink_create(args = { }, options = { })
    process_request_using_class(Requests::QuicklinkCreate, args, options)
  end

  def quicklink_share(args = { }, options = { })
    process_request_using_class(Requests::QuicklinkShare, args, options)
  end

  def tag_edit(args = { }, options = { })
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => 'tags',
        :http_method => :put,
        :http_success_code => '204',
        :parameters => [
          { :name => :currentName, :required => true, :send_in => :body },
          { :name => :newName, :required => true, :send_in => :body }
        ]
        # :http_success_code => %w(200 404),
      }.merge(options)
    )
    process_request(_request, options)
  end

  def tags_get
    http_client.get('tags')
  end

  def user_delete(args = { }, options = { })
    args = { :userId => args } if args.is_a?(String)
    _request = Requests::BaseRequest.new(
      args,
      {
        :http_path => '/users/#{arguments[:userId]}',
        :http_method => :delete,
        :http_success_code => '204',
        :parameters => [
          { :name => :userId, :required => true, :send_in => :query },
        ]
        # :http_success_code => %w(200 404),
      }.merge(options)
    )
    process_request(_request, options)
  end

  def users_get(args = { }, options = { })
    http_client.get('users?_pageSize=250')
  end



end
