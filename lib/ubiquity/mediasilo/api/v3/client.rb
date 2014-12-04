require 'ubiquity/mediasilo/api/v3/http_client'

class Ubiquity::MediaSilo::API::V3::Client

  attr_accessor :logger

  attr_accessor :http_client

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

  def asset_create(args = { })
    response = http_client.post('/assets', args)
  end

  def asset_delete(asset_id)
    asset_id = asset_id[:id] if asset_id.is_a?(Hash)
    response = http_client.delete('/assets/%s' % asset_id)
  end

  def folder_create(args = { })
    response = http_client.post('/folders', args)
  end

  def folder_delete(folder_id)
    folder_id = folder_id[:id] if folder_id.is_a?(Hash)
    response = http_client.delete('/folders/%s' % folder_id)
  end

  def project_create(args = { })
    response = http_client.post('/projects', args)
  end

  def project_delete(project_id)
    project_id = project_id[:id] if project_id.is_a?(Hash)
    response = http_client.delete('/projects/%s' % project_id)
  end

  def project_get_by_id(project_id)
    project_id = project_id[:id] if project_id.is_a?(Hash)
    response = http_client.get('/projects/%s' % project_id)
  end

  def projects_get
    response = http_client.get('/projects')
  end

end
