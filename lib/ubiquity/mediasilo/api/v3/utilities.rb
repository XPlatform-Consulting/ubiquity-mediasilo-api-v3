require 'ubiquity/mediasilo/api/v3/client'
require 'open-uri' # for download_file

class Exception
  def prefix_message(message_prefix = nil)
    begin
      raise self, "#{message_prefix ? "#{message_prefix} " : ''}#{message}", backtrace
    rescue Exception => e
      return e
    end
  end
end

class Ubiquity::MediaSilo::API::V3::Utilities < Ubiquity::MediaSilo::API::V3::Client

  # VALID_ASSET_SEARCH_FIELD_NAMES = %w(approvalStatus archiveStatus averageRating commentCount dateCreated dateModified derivatives description external fileName folderId id myRating permissions private progress projectId tags title transcriptStatus type uploadedBy)
  # VALID_ASSET_SEARCH_FIELDS = {
  #   :approvalstatus => 'approvalStatus',
  #   :archivestatus => 'archiveStatus',
  #   :averagerating => 'averageRating',
  #   :commentcount => 'commentCount',
  #   :datecreated => 'dateCreated',
  #   :datemodified => 'dateModified',
  #   :derivatives => 'derivatives',
  #   :description => 'description',
  #   :external => 'external',
  #   :filename => 'fileName',
  #   :folderid => 'folderId',
  #   :id => 'id',
  #   :metadatamatch => 'metadatamatch',
  #   :myrating => 'myRating', :permissions => 'permissions', :private => 'private', :progress => 'progress', :projectid => 'projectId', :tags => 'tags', :title => 'title', :transcriptstatus => 'transcriptStatus', :type => 'type', :uploadedby => 'uploadedBy' }


  def default_case_sensitive_search
    true
  end

  # Creates an asset building any missing parts of the path (Project/Folder/Asset)
  #
  # Required Parameters
  #   :url
  #   :mediasilo_path or :file_path
  #
  # Optional Parameters
  #   :metadata
  #   :overwrite_existing_asset
  #   :asset_search_field_name
  def asset_create_using_path(args = {})

    file_url = args[:url] || args[:file_url] || args[:source_url]
    raise ArgumentError ':url is a required parameter.' unless file_url

    file_path = args[:mediasilo_path] || args[:file_path]
    raise ArgumentError ':mediasilo_path is a required parameter.' unless file_path

    ms_metadata = args[:metadata]

    asset_title                                   = args[:title]
    asset_description                             = args[:description]
    additional_asset_create_params                = {}
    additional_asset_create_params['title']       = asset_title if asset_title
    additional_asset_create_params['description'] = asset_description if asset_description

    overwrite_existing_asset = args.fetch(:overwrite_existing_asset, false)
    asset_search_field_name  = args[:asset_search_field_name] || :filename

    #logger.info { "Creating Asset on MediaSilo Using File Path: '#{file_path}'. File URL: #{file_url}" }

    #ms_uuid = ms.asset_create(file_url, { }, ms_project)
    path_create_options = {
        :overwrite_existing_asset       => overwrite_existing_asset,
        :additional_asset_create_params => additional_asset_create_params,
        :asset_search_field_name        => asset_search_field_name
    }
    begin
      result = path_create(file_path, true, file_url, ms_metadata, path_create_options)
      # rescue => e
      #   raise e, "Exception Creating Asset Using File Path. #{e.message}", e.backtrace
    end

    output_values          = {}
    output_values[:result] = result

    return false unless result and result.has_key?(:asset)
    #return publish_error('Error creating asset.') unless result and result.has_key?(:asset)

    result_asset = result[:asset]
    if result_asset == false
      ms_asset_id = false
    elsif result[:asset_missing] == false
      ms_asset_id = result[:existing][:asset]['id'] # if not result[:existing][:asset]['uuid'].nil?
    elsif result_asset.is_a?(Array)

      #Metadata creation failed but asset was created Array(false, "uuid")
      #TODO: HANDLE CASE WHERE METADATA IS NOT CREATED BUT THE ASSET IS
      ms_asset_id = result_asset[1]

    else
      ms_asset_id = result_asset['id']
      ms_asset_id ||= result_asset
    end
    #Setting metadata during asset_create doesn't work so we set it here
    #response = ms.metadata_create(ms_uuid, ms_metadata) unless ms_metadata.nil?

    if ms_asset_id
      output_values[:asset_id] = ms_asset_id
      return output_values
    else
      #return publish_error("Error creating asset.\nResponse: #{response}\nMS UUID: #{ms_uuid}\nMS Creating Missing Path Result: #{result}")
      return false
    end
  end

  alias :asset_create_using_file_path :asset_create_using_path

  def asset_derivatives_transform_to_hash(derivatives)
    return {} unless derivatives.is_a?(Array)
    _derivatives = derivatives.map do |d|
      strategies      = d['strategies']

      d['strategies'] = Hash[strategies.map { |s| [s['type'], s] }] if strategies

      [d['type'], d]
    end
    Hash[_derivatives]
  end

  # Downloads a file from a URI or file location and saves it to a local path
  #
  # @param [String] download_file_path The source path of the file being downloaded
  # @param [String] destination_file_path The destination path for the file being downloaded
  # @param [Boolean] overwrite Determines if the destination file will be overwritten if it is found to exist
  #
  # @return [Hash]
  #   * :download_file_path [String] The source path of the file being downloaded
  #   * :overwrite [Boolean] The value of the overwrite parameter when the method was called
  #   * :file_downloaded [Boolean] Indicates if the file was downloaded, will be false if overwrite was true and the file existed
  #   * :destination_file_existed [String|Boolean] The value will be 'unknown' if overwrite is true because the file exist check will not have been run inside of the method
  #   * :destination_file_path [String] The destination path for the file being downloaded
  def download_file(download_file_path, destination_file_path, overwrite = false)
    logger.debug { "Downloading '#{download_file_path}' -> '#{destination_file_path}' Overwrite: #{overwrite}" }
    file_existed = 'unknown'
    if overwrite or not (file_existed = File.exists?(destination_file_path))
      File.open(destination_file_path, 'wb') { |tf|
        open(download_file_path) { |sf| tf.write sf.read }
      }
      file_downloaded = true
    else
      file_downloaded = false
    end
    return { :download_file_path => download_file_path, :overwrite => overwrite, :file_downloaded => file_downloaded, :destination_file_existed => file_existed, :destination_file_path => destination_file_path }
  end

  # @param [Object]  derivative_name Known options are proxy, proxy2m, source, and waveform
  # @param [Object]  asset
  # @param [Object]  destination_file_path
  # @param [Object]  overwrite
  # @param [Object]  field_name
  # @return [Hash]
  def asset_download_derivative(derivative_name, asset, destination_file_path, overwrite = false, field_name = 'url')
    return asset.map { |a| asset_download_derivative(derivative_name, a, destination_file_path, overwrite) } if asset.is_a?(Array)
    asset        = asset_get_by_id_extended({ :asset_id => asset }, :include_derivatives_hash => true) if asset.is_a? String
    _derivatives = asset['derivatives_hash'] || begin
      asset_derivatives_transform_to_hash(asset['derivatives'])
    end

    file_to_download = _derivatives[derivative_name][field_name]
    asset_download_resource(file_to_download, destination_file_path, overwrite)
  end

  # @param [Array | String | Hash]  asset
  # @param [String]  destination_file_path
  # @param [Boolean]  overwrite
  # @return [Hash]
  def asset_download_poster_frame_file(asset, destination_file_path, overwrite = false)
    return asset.map { |a| asset_download_poster_frame_file(a, destination_file_path, overwrite) } if asset.is_a?(Array)
    asset = asset_get_by_id(:asset_id => asset) if asset.is_a? String

    file_to_download = asset['posterFrame']
    asset_download_resource(file_to_download, destination_file_path, overwrite)
  end

  # @param [String|Hash] asset
  # @param [String] destination_file_path
  # @param [Boolean] overwrite
  # @return [Hash] see (MediaSilo#download_file)
  def asset_download_proxy_file(asset, destination_file_path, overwrite = false)
    asset_download_derivative('proxy', asset, destination_file_path, overwrite)
  end

  # @param [String] download_file_path
  # @param [String] destination_file_path
  # @param [Boolean] overwrite
  def asset_download_resource(download_file_path, destination_file_path, overwrite = false)
    # download_file_path = URI.encode(download_file_path)

    destination_file_path = File.join(destination_file_path, File.basename(URI.decode(download_file_path))) if File.directory? destination_file_path
    download_file(download_file_path, destination_file_path, overwrite)
  end

  # @param [String|Hash] asset
  # @param [String] destination_file_path
  # @param [Boolean] overwrite
  # @return [Hash] see (MediaSilo#download_file)
  def asset_download_source_file(asset, destination_file_path, overwrite = false)
    asset_download_derivative('source', asset, destination_file_path, overwrite)
  end

  def asset_download_proxy_poster_frame_file(asset, destination_file_path, overwrite = false)
    asset_download_derivative('proxy', asset, destination_file_path, overwrite, 'posterFrame')
  end

  def asset_download_proxy_thumbnail_file(asset, destination_file_path, overwrite = false)
    asset_download_derivative('proxy', asset, destination_file_path, overwrite, 'thumbnail')
  end


  # @param [String] asset_uuid
  # @param [Hash] args A hash of arguments
  # @option args [String] :asset_id The uuid of the asset to edit
  # @option args [Hash] :metadata The asset's metadata.
  # @option args [Boolean] :mirror_metadata If set to true then the metadata will mirror :metadata which means that any keys existing on MediaSilo that don't exists in :metadata will be deleted from MediaSilo.
  # @option args [Array] :tags_to_add_to_asset An array of tag names to add to the asset
  # @option args [Array] :tags_to_remove_from_asset An array of tag names to remove from the asset
  # @option args [Boolean|Hash|Array] :add_quicklink_to_asset
  # @option args (see MediaSilo#asset_edit)
  def asset_edit_extended(asset_id, args = {}, options = {})
    logger.debug { "Asset Edit Extended: #{asset_id} ARGS: #{args.inspect}" }
    if asset_id.is_a?(Hash)
      options  = args.dup
      args     = asset_id.dup
      asset_id = args[:asset_id]
      raise ArgumentError, 'Error Editing Asset. Missing required argument :asset_id' unless asset_id
    else
      args            = args.dup
      args[:asset_id] = asset_id
    end

    ms_metadata     = args.delete(:metadata) { false }
    mirror_metadata = args.delete(:mirror_metadata) { false }
    #
    add_tag_to_asset = args.delete(:tags_to_add) { [] }
    add_tag_to_asset = args.delete(:tags_to_add_to_asset) { add_tag_to_asset }

    remove_tag_from_asset = args.delete(:tags_to_remove) { [] }
    remove_tag_from_asset = args.delete(:tags_to_remove_from_asset) { remove_tag_from_asset }
    #
    # add_quicklink_to_asset = args.delete(:add_quicklink_to_asset) { false }

    _response = { :success => false }
    if args[:title] or args[:description]
      result                          = asset_edit(args)
      _response[:asset_edit_result]   = result
      _response[:asset_edit_response] = response
      _response[:asset_edit_success]  = success?
      unless success?
        _response[:error_message] = "Error Editing Asset. #{error_message}"
        return _response
      end
    end

    if ms_metadata.is_a?(Hash)
      if mirror_metadata
        result = metadata_mirror(:asset_id => asset_id, :metadata => ms_metadata)
      else
        result = metadata_create_or_update(:asset_id => asset_id, :metadata => ms_metadata)
      end
      _response[:metadata_edit_result]   = result
      _response[:metadata_edit_response] = response
      _response[:metadata_edit_success]  = success?
      unless success?
        _response[:error_message] = "Error Editing Asset's Metadata. #{error_message}"
        return _response
      end
    end

    batch_execute do
      unless remove_tag_from_asset.nil? or remove_tag_from_asset.empty?
        [*remove_tag_from_asset].uniq.each { |tag_to_remove| asset_tag_remove(:asset_id => asset_id, :tag => tag_to_remove) if tag_to_remove.is_a?(String); }
      end
      unless add_tag_to_asset.nil? or add_tag_to_asset.empty?
        [*add_tag_to_asset].uniq.each { |tag_to_add| asset_tag_add(:asset_id => asset_id, :tags => tag_to_add) if tag_to_add.is_a?(String) }
      end
    end

    #
    # if add_quicklink_to_asset
    #   add_quicklink_to_asset.is_a?(Hash) ? quicklink_create(asset_id, add_quicklink_to_asset) : quicklink_create(asset_id)
    #   _response[:quicklink_create_response] = response.body_parsed
    #   _response[:quicklink_create_success] = success?
    #   unless success?
    #     _response[:error_message] = "Error Adding Quicklink to Asset. #{error_message}"
    #     return _response
    #   end
    # end

    _response[:success] = true
    _response
  end

  # @param [String] search_field_name
  # @param [String] search_value
  # @param [String|nil] project_id
  # @param [String|nil] folder_id
  # @param [Hash] options
  # @option options [Boolean] :limit_to_project_root (true)
  # @return [Array]
  def asset_get_by_field_search(search_field_name, search_value, project_id = nil, folder_id = nil, options = {})

    path = if folder_id and !folder_id == 0
             limit_to_project_root = false
             "/folders/#{folder_id}/assets"
           elsif project_id
             limit_to_project_root = options.fetch(:limit_to_project_root, true)
             "/projects/#{project_id}/assets"
           else
             limit_to_project_root = false
             '/assets'
           end

    # _search_field_name = VALID_ASSET_SEARCH_FIELDS[search_field_name.to_s.downcase.to_sym]
    # raise ArgumentError, "The argument for the search_field_name parameter is invalid. '#{search_field_name}' not found in #{VALID_ASSET_SEARCH_FIELDS.values.inspect}" unless _search_field_name

    _search_field_name      = search_field_name.to_s
    search_operator_default = search_value.is_a?(Array) ? 'in' : nil
    search_operator         = options[:operator] || search_operator_default
    case search_operator
    when nil
      search_field_query = { _search_field_name => search_value }
    else
      search_field_query = { _search_field_name => %({"#{search_operator}":"#{[*search_value].join(',')}"}) }
    end

    # query = { :type => '{"in":"video,image,document,archive,audio"}' }.merge((options[:query] || { })).merge(search_field_query)
    query  = (options[:query] || {}).merge(search_field_query)
    assets = http_client.get(path, query)
    assets = [] if http_client.response.code == '404'
    limit_to_project_root ? assets.delete_if { |v| v['folderId'] } : assets
  end

  # @param [Object]  args
  # @param [Object]  options
  # @return [Hash]
  def asset_get_by_id_extended(args = {}, options = {})
    include_metadata         = options.delete(:include_metadata)
    include_derivatives_hash = options.delete(:include_derivatives_hash) { true }
    transform_metadata       = options.delete(:transform_metadata) { true }

    asset_id = args[:asset_id]

    asset = asset_get_by_id({ :asset_id => asset_id }, options)

    if include_metadata
      md                = metadata_get({ :asset_id => asset['id'] }, options)
      md                = metadata_transform_to_hash(md) if transform_metadata
      asset['metadata'] = md
    end

    if include_derivatives_hash
      _derivatives              = asset['derivatives']
      asset['derivatives_hash'] = asset_derivatives_transform_to_hash(_derivatives)
    end

    asset
  end

  # @param [Hash] args
  # @param [Hash] options
  # @option options [Boolean] :include_metadata
  # @option options [Boolean] :transform_metadata Will cause metadata to be transformed to a simple Hash
  def assets_get_extended(args = {}, options = {})
    include_metadata         = options.delete(:include_metadata)
    include_derivatives_hash = options.delete(:include_derivatives_hash) { true }
    transform_metadata       = options.delete(:transform_metadata) { true }

    assets = assets_get(args, options)

    assets.map! do |a|

      if include_metadata
        md            = metadata_get(:asset_id => a['id'])
        md            = metadata_transform_to_hash(md) if transform_metadata
        a['metadata'] = md
      end

      if include_derivatives_hash
        _derivatives = a['derivatives'].map do |d|
          strategies      = d['strategies']

          d['strategies'] = Hash[strategies.map { |s| [s['type'], s] }] if strategies

          [d['type'], d]
        end

        a['derivatives_hash'] = Hash[_derivatives]
      end

      a
    end if (include_metadata || include_derivatives_hash)

    assets
  end


  # Refines asset_get_by_field_search results to exact (full string case sensitive) matches
  #
  # @param [String] search_value
  # @param [String] field_name The field to search.
  #   ["approvalstatus", "archivestatus", "averagerating", "datecreated", "datemodified", "description",
  #    "duration", "external", "filename", "height", "progress", "rating", "secure", "size", "thumbnail_large",
  #    "thumbnail_small", "title", "totalcomments", "transcriptstatus", "type", "uploaduser", "uuid", "width"]
  # @param [Array] assets The assets as returned by asset_adavanced_search_by_results
  # @param [Hash] options
  # @option options [Boolean] :return_first_match (false)
  # @option options [Boolean] :match_full_string (true)
  # @option options [Boolean] :case_sensitive (#default_case_sensitive_search)
  def refine_asset_get_by_field_search_results(field_name, search_value, assets, options)
    return unless assets
    return_first_match = options.fetch(:return_first_match, false)
    match_full_string  = options.fetch(:match_full_string, true)
    case_sensitive     = options.fetch(:case_sensitive, default_case_sensitive_search)
    search_value       = search_value.to_s.downcase unless case_sensitive
    method             = return_first_match ? :drop_while : :delete_if
    assets.send(method) do |asset|
      asset_value = case_sensitive ? asset[field_name] : asset[field_name].to_s.downcase
      nomatch     = match_full_string ? (asset_value != search_value) : (!asset_value.include?(search_value))
      #logger.debug "COMPARING: '#{search_value}' #{nomatch ? '!' : '='}= '#{asset_value}'"
      nomatch
    end if assets and (match_full_string or case_sensitive)
    return assets.first if assets and return_first_match
    assets
  end

  def asset_get_by_filename(asset_name, project_id = nil, folder_id = nil, options = {})
    assets = asset_get_by_field_search(:filename, asset_name, project_id, folder_id, options)
    refine_asset_get_by_field_search_results('fileName', asset_name, assets, options)
  end

  def asset_get_by_title(asset_name, project_id = nil, folder_id = nil, options = {})
    assets = asset_get_by_field_search(:title, asset_name, project_id, folder_id, options)
    refine_asset_get_by_field_search_results('title', asset_name, assets, options)
  end

  def folder_get_by_name(project_id, folder_name, parent_id, options = {})
    logger.debug { "Searching For Folder by Name: '#{folder_name}' Project Id: '#{project_id}' Parent Id: '#{parent_id}'" }
    case_sensitive     = options.fetch(:case_sensitive, default_case_sensitive_search)
    return_all_matches = !options.fetch(:return_first_match, false)

    folders = options[:folders] || (parent_id ? folders_get_by_parent_id(:parent_id => parent_id) : folders_get_by_project_id(:project_id => project_id))
    return false unless folders

    # Use delete_if instead of keep_if to be ruby 1.8 compatible
    folders.dup.delete_if do |folder|
      folder_name_to_test = folder['name']
      folder_name_to_test.upcase! unless case_sensitive
      no_match = (folder_name_to_test != folder_name)
      return folder unless no_match or return_all_matches
      no_match
    end
    return nil unless return_all_matches
    folders
  end

  # # A metadata creation utility method that checks for existing keys to avoid duplication
  # #
  # # @param [String] asset_id
  # # @param [Hash] metadata
  # # @return [Boolean]
  # def metadata_create_if_not_exists(asset_id, metadata)
  #   return asset_id.map { |au| metadata_create_if_not_exists(au, metadata) } if asset_id.is_a?(Array)
  #   return unless metadata.is_a?(Hash) and !metadata.empty?
  #
  #   md_existing = metadata_get_by_asset_uuid(asset_id)
  #   md_existing_keys = {}
  #   md_existing.each do |ms_md|
  #     md_existing_keys[ms_md['key']] = ms_md
  #   end if md_existing.is_a?(Array)
  #
  #   md_to_create = [ ]
  #   md_to_edit = [ ]
  #
  #   metadata.each do |key, value|
  #     if md_existing_keys.has_key?(key)
  #       md_current = md_existing_keys[key]
  #       md_to_edit << { 'key' => key, 'value' => value } unless (md_current['value'] == value)
  #     else
  #       md_to_create << { 'key' => key, 'value' => value }
  #     end
  #   end
  #
  #   # logger.debug { <<-MD
  #   #
  #   #   Metadata
  #   #
  #   #     Create
  #   #       #{PP.pp(md_to_create, '')}
  #   #
  #   #     Edit
  #   #       #{PP.pp(md_to_edit, '')}
  #   # MD
  #   # }
  #
  #   batch_execute do
  #     #md_to_edit.each { |data| metadata_update(data.merge({ :asset_id => asset_id })) }
  #     #md_to_create.each { |data| next unless data and !data.empty?; metadata_create(data.merge({ :asset_id => asset_id })) }
  #
  #     md_to_edit.each_slice(50) { |data| metadata_update(:asset_id => asset_id, :metadata => data) }
  #     md_to_create.each_slice(50) { |data| logger.debug { "Data: #{data.inspect}" };  metadata_create(:asset_id => asset_id, :metadata => data) }
  #
  #   end
  #
  # end

  # # A method that mirrors the metadata passed to the asset, deleting any keys that don't exist in the metadata param
  # #
  # # @param [String] asset_id
  # # @param [Hash] metadata
  # def metadata_mirror(asset_id, metadata = { })
  #   return asset_id.map { |au| metadata_mirror(au, metadata) } if asset_id.is_a?(Array)
  #
  #   md_to_delete = [ ]
  #   md_existing_keys = { }
  #
  #   md_existing = metadata_get_by_asset_uuid(asset_id)
  #   md_existing.each do |ms_md|
  #     ms_md_key = ms_md['key']
  #     if metadata.key?(ms_md_key)
  #       md_existing_keys[ms_md_key] = ms_md
  #     else
  #       md_to_delete << ms_md_key
  #     end
  #   end
  #
  #   md_to_create = [ ]
  #   md_to_edit = [ ]
  #
  #   metadata.each do |key, value|
  #     if md_existing_keys.has_key?(key)
  #       md_current = md_existing_keys[key]
  #       md_to_edit << { 'key' => key, 'value' => value } unless (md_current['value'] == value)
  #     else
  #       md_to_create << { 'key' => key, 'value' => value }
  #     end
  #   end
  #
  #   batch_execute do
  #     md_to_edit.each { |data| metadata_update(data.merge({ :asset_id => asset_id })) }
  #     md_to_create.each { |data| metadata_create(data.merge({ :asset_id => asset_id })) }
  #     md_to_delete.each { |data| metadata_delete({ :asset_id => asset_id, :metadata_key => data }) }
  #   end
  #
  # end

  # @param [Array] metadata_in
  def metadata_transform_to_hash(metadata_in)
    case metadata_in
    when Array
      # This is what we want
      return Hash[metadata_in.map { |m| [m['key'], m['value']] }]
    when Hash
      return metadata_in
    else
      return {}
    end
  end

  # Checks to see if a project/folder/asset path exists and records each as existing or missing
  #
  # @param [String] path The path to be checked for existence. Format: project[/folder][/filename]
  # @param [Boolean] path_contains_asset (false) Indicates that the path contains an asset filename
  # @param [Hash] options ({ })
  # @option options [Boolean] :asset_name_field (:filename)
  # (@see #resolve_path)
  def path_check(path, path_contains_asset = false, options = {})
    return false unless path

    # Remove any and all instances of '/' from the beginning of the path
    path = path[1..-1] while path.start_with? '/'

    path_ary = path.split('/')

    existing_path_result = resolve_path(path, path_contains_asset, options)
    existing_path_ary    = existing_path_result[:id_path_ary]
    check_path_length    = path_ary.length

    # Get a count of the number of elements which were found to exist
    existing_path_length = existing_path_ary.length

    # Drop the first n elements of the array which corresponds to the number of elements found to be existing
    missing_path = path_ary.drop(existing_path_length)
    # In the following logic tree the goal is indicate what was searched for and what was found. If we didn't search
    # for the component (folder/asset) then we don't want to set the missing indicator var
    # (folder_missing/asset_missing) for component as a boolean but instead leave it nil.
    missing_path_length = missing_path.length
    if missing_path_length > 0
      # something is missing

      if missing_path_length == check_path_length
        # everything is missing in our path

        project_missing = true
        if path_contains_asset
          # we are missing everything and we were looking for an asset so it must be missing
          asset_missing = true

          if check_path_length > 2
            #if we were looking for more than two things (project, folder, and asset) and we are missing everything then folders are missing also
            searched_folders = true
            folder_missing   = true
          else

            #if we are only looking for 2 things then that is only project and asset, folders weren't in the path so we aren't missing them
            searched_folders = false
            folder_missing   = false
          end
        else
          if check_path_length > 1
            # If we are looking for more than one thing then it was project and folder and both are missing
            searched_folders = true
            folder_missing   = true
          else
            searched_folders = false
            folder_missing   = false
          end
        end
      else
        #we have found at least one thing and it starts with project
        project_missing = false
        if path_contains_asset
          #missing at least 1 and the asset is at the end so we know it's missing
          asset_missing = true
          if missing_path_length == 1
            #if we are only missing one thing and it's the asset then it's not a folder!
            folder_missing   = false
            searched_folders = check_path_length > 2
          else
            # missing_path_length is more than 1
            if check_path_length > 2
              #we are looking for project, folder, and asset and missing at least 3 things so they are all missing
              searched_folders = true
              folder_missing   = true
            else
              #we are only looking for project and asset so no folders are missing
              searched_folders = false
              folder_missing   = false
            end
          end
        else
          #if we are missing something and the project was found and there was no asset then it must be a folder
          searched_folders = true
          folder_missing   = true
        end
      end
    else
      searched_folders = !existing_path_result[:folders].empty?
      project_missing  = folder_missing = asset_missing = false
    end

    {
        :check_path_ary   => path_ary,
        :existing         => existing_path_result,
        :missing_path     => missing_path,
        :searched_folders => searched_folders,
        :project_missing  => project_missing,
        :folder_missing   => folder_missing,
        :asset_missing    => asset_missing,
    }
  end

  alias :check_path :path_check


  # Calls check_path to see if any part of a project/folder/asset path are missing from MediaSilo and creates any part that is missing
  #
  # @param [String] path The path to create inside of MediaSilo
  # @param [Boolean] contains_asset see #path_resolve
  # @param [String|nil] asset_url
  # @param [Hash|nil] metadata
  # @param [Hash] options
  # @option options [Hash] :additional_asset_create_params Additional arguments to pass to the asset_create call
  # @option options [Boolean] :overwrite_asset Will cause the asset to be deleted and recreated
  # @option options [Boolean] :path_creation_delay A delay between folder_create calls to allow
  # @return [Hash]
  #  {
  #    :check_path_ary=>["create_missing_path_test"],
  #    :existing=>{
  #        :name_path=>"/",
  #        :id_path=>"/",
  #        :name_path_ary=>[],
  #        :id_path_ary=>[],
  #        :project=>false,
  #        :asset=>nil,
  #        :folders=>[]
  #    },
  #    :missing_path=>[],
  #    :searched_folders=>false,
  #    :project_missing=>true,
  #    :folder_missing=>false,
  #    :asset_missing=>nil,
  #    :project=>{
  #        "id"=>30620,
  #        "datecreated"=>"June, 05 2013 15:20:15",
  #        "description"=>"",
  #        "uuid"=>"15C84A5F-B2D9-0E2F-507D94189F8A1FDC",
  #        "name"=>"create_missing_path_test"
  #    },
  #    :project_id=>30620,
  #    :parent_folder_id=>0
  #  }
  def path_create(path, contains_asset = false, asset_url = nil, metadata = nil, options = {})
    overwrite_asset                = options.fetch(:overwrite_asset, false)
    additional_asset_create_params = options[:additional_asset_create_params] || {}
    path_creation_delay            = options[:path_creation_delay] || 10
    asset_search_field_name        = options[:asset_search_field_name] || :filename

    cp_result = check_path(path, contains_asset, :asset_search_field_name => asset_search_field_name)
    logger.debug { "CHECK PATH RESULT #{cp_result.inspect}" }
    return false unless cp_result

    project_missing = cp_result[:project_missing]
    folder_missing  = cp_result[:folder_missing]
    asset_missing   = cp_result[:asset_missing]

    existing = cp_result[:existing]

    asset = existing[:asset]

    # This was meant as a Bypass if nothing needed to be done, complicated code maintenance
    # unless project_missing or folder_missing or asset_missing or (!asset_missing and overwrite_asset)
    #   project_id = cp_result[:existing][:id_path_ary].first
    #   asset = cp_result[:existing][:asset]
    #   if contains_asset
    #     asset_id = cp_result[:existing][:id_path_ary].last
    #     parent_folder_id = cp_result[:existing][:id_path_ary].fetch(-2)
    #
    #     asset_edit_extended(asset_id, additional_asset_create_params) if metadata and !metadata.empty?
    #     # metadata_create_if_not_exists(asset_id, metadata) if metadata and !metadata.empty?
    #   else
    #     asset_id = nil
    #     parent_folder_id = cp_result[:existing][:id_path_ary].last
    #   end
    #
    #   result = cp_result.merge({ :project_id => project_id, :parent_folder_id => parent_folder_id, :asset_id => asset_id, :asset => asset })
    #   logger.debug { "Create Missing Path Result: #{result.inspect}" }
    #   return result
    # end
    searched_folders = cp_result[:searched_folders]

    missing_path = cp_result[:missing_path]

    project_name = cp_result[:check_path_ary][0]
    #logger.debug "PMP: #{missing_path}"
    if project_missing
      logger.debug { "Missing Project - Creating Project '#{project_name}'" }
      project = project_create(project_name)
      raise "Error Creating Project. Response: #{project}" unless project.is_a?(Hash)

      cp_result[:project] = project
      project_id          = project['id']
      missing_path.shift
      logger.debug { "Created Project '#{project_name}' - #{project_id}" }
    else
      project_id = existing[:id_path_ary].first
    end

    if searched_folders
      if folder_missing
        # logger.debug "FMP: #{missing_path}"

        parent_folder_id = (existing[:id_path_ary].length <= 1) ? 0 : existing[:id_path_ary].last

        asset_name       = missing_path.pop if contains_asset

        previous_missing = project_missing
        missing_path.each do |folder_name|
          sleep path_creation_delay if path_creation_delay and previous_missing
          begin
            logger.debug { "Creating folder '#{folder_name}' parent id: #{parent_folder_id} project id: #{project_id}" }
            new_folder = folder_create(:name => folder_name, :project_id => project_id, :parent_id => parent_folder_id)
            raise "Error Creating Folder. Response: #{new_folder}" unless new_folder.is_a?(Hash)

            logger.debug { "New Folder: #{new_folder.inspect}" }
            parent_folder_id = new_folder['id']
            logger.debug { "Folder Created #{new_folder} - #{parent_folder_id}" }
          rescue => e
            raise e.prefix_message("Failed to create folder '#{folder_name}' parent id: '#{parent_folder_id}' project id: '#{project_id}'. Exception:")
          end
          previous_missing = true
        end

      else
        if contains_asset and not asset_missing
          parent_folder_id = existing[:id_path_ary].fetch(-2)
        else
          parent_folder_id = existing[:id_path_ary].last
        end
      end
    else
      parent_folder_id = 0
    end

    if contains_asset
      additional_asset_create_params              = {} unless additional_asset_create_params.is_a?(Hash)
      additional_asset_create_params['folderId']  = parent_folder_id
      additional_asset_create_params['projectId'] = project_id
      additional_asset_create_params[:metadata]   = metadata
      additional_asset_create_params[:source_url] = asset_url

      if asset_missing
        asset = asset_create(additional_asset_create_params)
        raise "Error Creating Asset: #{asset.inspect} Args: #{additional_asset_create_params.inspect}" unless success?
      else
        if overwrite_asset
          asset_id = existing[:id_path_ary].last
          begin
            raise "Error Message: #{error_message}" unless asset_delete(asset_id)
          rescue => e
            raise e.prefix_message("Error Deleting Existing Asset. Asset ID: #{asset_id} Exception: ")
          end
          asset = asset_create(additional_asset_create_params)
          raise "Error Creating Asset: #{asset.inspect} Args: #{additional_asset_create_params.inspect}" unless success?
        end
      end

      additional_asset_create_params = additional_asset_create_params.delete_if { |k, v| asset[k] == v }
      asset_edit_extended(asset['id'], additional_asset_create_params) unless additional_asset_create_params.empty?
      # metadata_create_if_not_exists(asset['id'], metadata) if metadata and !metadata.empty?

      cp_result[:asset] = asset
    end
    result = cp_result.merge({ :project_id => project_id, :parent_folder_id => parent_folder_id })
    logger.debug { "Create Missing Path Result: #{result.inspect}" }
    return result
  end

  alias :create_path :path_create

  def path_delete(path, options = {})
    raise_exception_on_error = options.fetch(:raise_exception_on_error, true)
    recursive                = (options.fetch(:recursive, false) === true) ? true : false
    include_assets           = (options.fetch(:include_assets, false) === true) ? true : false

    path                     = path[1..-1] if path.start_with? '/' # Remove the leading slash if it is present
    path_ary                 = path.split('/') # Turn the path into an array of names

    raise ArgumentError, 'Path is empty. Nothing to do.' if path_ary.empty?

    if path_ary.last == '*'
      path_ary.pop

      if path_ary.empty?
        delete_all_projects = options.fetch(:delete_all_projects)
        raise ArgumentError, 'Wildcard Project Deletion is not Enabled.' unless (delete_all_projects === true)

        projects = projects_get
        return projects.map { |project| path_delete(project['name'], options) }
      end

      delete_contents_only = true
    else
      delete_contents_only = options.fetch(:delete_contents_only, false)
    end

    result = check_path(path_ary.join('/'))
    raise "Error checking path. '#{error_message}'" unless result

    existing_path = result[:existing][:id_path_ary]
    missing_path  = result[:missing_path]

    #The path was not found
    raise "Path not found. Path: '#{path}' Check Path Result: #{result.inspect}" unless missing_path.empty?

    id_path_ary = existing_path

    project_id = id_path_ary.shift # Pull the project_id out of the beginning of the array

    if id_path_ary.empty?
      folder_id = 0
    else
      folder_id = id_path_ary.last
    end

    path_delete_by_id(project_id, folder_id, recursive, include_assets, delete_contents_only, options)
  rescue ArgumentError, RuntimeError => e
    raise e if raise_exception_on_error
    return false
  end

  # Deletes a project's and/or folder's contents.
  #
  # @param [String|Integer] project_id The id of the project that you wish to delete.
  # @param [String|Integer] folder_id (0) The parent_folder in the project that you would want to delete the
  #   contents of. Defaults to 0 which is the root folder of the project.
  # @param [Boolean] recursive (false) Tells the method to recurse into any sub-folders. Usually you would want
  #   this to be true, but the default requires you to be explicit about wanting to delete sub-folders so the
  #   default is false.
  # @param [Boolean] include_assets (false) Tells the method to delete any assets in any directory that it
  #   traverses into. Usually you would want this to be true, but the default requires you to be explicit about
  #   wanting to delete assets so the default is false
  # @param [Boolean] delete_contents_only (true) Tells the method to not delete the parent object
  #   (project or folder) unless this is set to true.
  # @param [Hash] options
  # @option option [Boolean] :dry_run
  # @option option [Boolean] :delete_assets_only Will only delete assets along the path but will leave the project
  #   and folders in place
  def path_delete_by_id(project_id, folder_id = 0, recursive = false, include_assets = false, delete_contents_only = true, options = {})
    dry_run            = options.fetch(:dry_run, false)
    delete_assets_only = options.fetch(:delete_assets_only, false)

    raise ArgumentError, 'include_assets must be true to use the delete_assets_only option.' if delete_assets_only and !include_assets

    @logger.debug { "Deleting Path By ID - Project ID: #{project_id} Folder ID: #{folder_id} Recursive: #{recursive} Include Assets: #{include_assets} Delete Contents Only: #{delete_contents_only} Options: #{options.inspect}" }

    if folder_id and folder_id != 0
      folders = folders_get_by_parent_id(folder_id) || []
    else
      folders = folders_get_by_project_id(project_id) || []
    end
    folders = [] unless folders.is_a?(Array)
    if recursive
      folders        = [] if folders.is_a?(String)
      total_folders  = folders.length
      folder_counter = 0
      folders.delete_if do |folder|
        folder_counter += 1

        @logger.debug { "Deleting Contents of Folder #{folder_counter} of #{total_folders} - #{folder}" }

        # Pass delete_assets_only as the delete_contents_only argument. This way if we aren't deleting assets only then
        # sub-folders and assets will get deleted recursively, otherwise only assets will be deleted
        path_delete_by_id(project_id, folder['id'], recursive, include_assets, delete_assets_only, options)
      end
    end


    if include_assets
      if folder_id == 0
        assets = assets_get_by_project_id(:id => project_id)
      else
        assets = assets_get_by_folder_id(:id => folder_id)
      end
      assets        = [] unless assets.is_a?(Array)
      total_assets  = assets.length
      asset_counter = 0

      # batch_execute {
      #   assets.each { |asset| asset_delete(asset['id']) }
      # }

      response = assets.map { |asset| asset_delete(asset['id']) }

      # if dry_run
      #   assets = [ ]
      # else
      #   assets = response.dup.delete_if { |r| %w(204 404).include?(r['httpStatus']) } unless assets.empty?
      # end

      assets = []

      # assets.delete_if { |asset|
      #   asset_counter += 1
      #
      #   dry_run ? true : asset_delete(asset['id'])
      # }
    else
      assets = [] # make assets.empty? pass later on. let ms throw an error if the project/folder isn't empty
    end

    unless delete_contents_only or delete_assets_only
      if folders.empty? and assets.empty?
        if folder_id === 0
          @logger.debug { "Deleting Project #{project_id}" }
          return (dry_run ? true : project_delete(project_id))
        else
          @logger.debug { "Deleting Folder #{folder_id}" }
          return (dry_run ? true : folder_delete(folder_id))
        end
      else
        return true if dry_run
        warn "Assets remaining in project/folder: #{project_id}/#{folder_id} : Assets: #{assets.inspect}" unless assets.empty?
        warn "Folders remaining in project/folder: #{project_id}/#{folder_id} : Folders: #{folders.inspect}" unless folders.empty?
        return false
      end
    end

    return true
  end


  def project_get_by_name(args = {}, options = {})
    project_name = case args
                   when String;
                     args
                   when Hash;
                     args[:name] || args[:project_name]
                   end

    case_sensitive     = options.fetch(:case_sensitive, default_case_sensitive_search)
    return_all_matches = !options.fetch(:return_first_match, false)


    projects = options[:projects] || projects_get
    logger.debug { "Searching Projects: #{projects.inspect}" }
    return false unless projects

    project_name.upcase! unless case_sensitive

    # Use delete_if instead of keep_if to be ruby 1.8 compatible
    projects = projects.dup.delete_if do |project|
      project_name_to_test = project['name']
      project_name_to_test.upcase! unless case_sensitive
      no_match = (project_name_to_test != project_name)
      logger.debug { "Comparing: #{project_name_to_test} #{no_match ? '!' : '='}= #{project_name}" }
      return project unless no_match or return_all_matches
      no_match
    end
    return nil unless return_all_matches
    projects
  end

  def path_resolve(path, path_contains_asset = false, options = {})
    logger.debug { "Resolving Path: '#{path}' Path Contains Asset: #{path_contains_asset} Options: #{options}" }

    return_first_matching_asset = options.fetch(:return_first_matching_asset, true)

    id_path_ary   = []
    name_path_ary = []

    if path.is_a?(String)
      # Remove any leading slashes
      path = path[1..-1] while path.start_with?('/')

      path_ary = path.split('/')
    elsif path.is_a?(Array)
      path_ary = path.dup
    else
      raise ArgumentError, "path is required to be a String or an Array. Path Class Name: #{path.class.name}"
    end

    asset_name = path_ary.pop if path_contains_asset

    # The first element must be the name of the project
    project_name = path_ary.shift
    raise ArgumentError, 'path must contain a project name.' unless project_name
    logger.debug { "Search for Project Name: #{project_name}" }
    project = project_get_by_name(project_name, :return_first_match => true, :projects => options[:projects])
    return {
        :name_path     => '/',
        :name_path_ary => [],

        :id_path       => '/',
        :id_path_ary   => [],

        :project       => nil,
        :asset         => nil,
        :folders       => []
    } if !project or project.empty?

    project_id = project['id']
    id_path_ary << project_id
    name_path_ary << project_name

    parsed_folders = (project && project['folderCount'] > 0) ? resolve_folder_path(project_id, path_ary) : nil
    if parsed_folders.nil?
      asset_folder_id = 0
      folders         = []
    else
      id_path_ary.concat(parsed_folders[:id_path_ary])
      name_path_ary.concat(parsed_folders[:name_path_ary])
      asset_folder_id = parsed_folders[:id_path_ary].last if path_contains_asset
      folders         = parsed_folders.fetch(:folder_ary, [])
    end

    asset = nil
    if path_contains_asset and (asset_folder_id or path_ary.length == 2)
      # The name of the attribute to search the asset name for (Valid options are :title or :filename)
      asset_name_field = options[:asset_search_field_name] || :filename
      case asset_name_field.to_s.downcase.to_sym
      when :filename, 'filename'
        asset = asset_get_by_filename(asset_name, project_id, asset_folder_id, :return_first_match => return_first_matching_asset)
      when :title, 'title'
        asset = asset_get_by_title(asset_name, project_id, asset_folder_id, :return_first_match => return_first_matching_asset)
      else
        raise ArgumentError, ":asset_name_field value is not a valid option. It must be :title or :filename. Current value: #{asset_name_field}"
      end

      if asset
        if asset.empty?


        elsif asset.is_a?(Array)
          # Just add the whole array to the array
          id_path_ary << asset.map { |_asset| _asset['id'] }
          name_path_ary << asset.map { |_asset| _asset['fileName'] }
        else
          id_path_ary << asset['id']
          name_path_ary << asset['fileName']
        end
      end
    end

    return {
        :name_path     => "/#{name_path_ary.join('/')}",
        :name_path_ary => name_path_ary,

        :id_path       => "/#{id_path_ary.join('/')}",
        :id_path_ary   => id_path_ary,

        :project       => project,
        :asset         => asset,
        :folders       => folders
    }
  end

  alias :resolve_path :path_resolve

  # Takes a file system type path and resolves the MediaSilo id's for each of the folders of that path
  #
  # @param [Integer] project_id The id of the project the folder resides in
  # @param [String] path A directory path separated by / of folders to traverse
  # @param [Integer] parent_id The ID of the parent folder to begin the search in
  def resolve_folder_path(project_id, path, parent_id = nil)
    if path.is_a?(Array)
      path_ary = path.dup
    elsif path.is_a? String
      path     = path[1..-1] while path.start_with?('/')
      path_ary = path.split('/')
    end

    return nil if !path_ary or path_ary.empty?

    id_path_ary   = []
    name_path_ary = []

    folder_name = path_ary.shift
    name_path_ary << folder_name

    folder = folder_get_by_name(project_id, folder_name, parent_id, :return_first_match => true)
    return nil unless folder

    folder_ary = [folder]

    folder_id = folder['id']

    id_path_ary << folder_id.to_s

    resolved_folder_path = (folder and folder['folderCount'] > 0) ? resolve_folder_path(project_id, path_ary, folder_id) : nil

    unless resolved_folder_path.nil?
      id_path_ary.concat(resolved_folder_path[:id_path_ary] || [])
      name_path_ary.concat(resolved_folder_path[:name_path_ary] || [])
      folder_ary.concat(resolved_folder_path[:folder_ary] || [])
    end

    return {
        :id_path_ary   => id_path_ary,
        :name_path_ary => name_path_ary,
        :folder_ary    => folder_ary
    }
  end

end
