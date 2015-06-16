module Ubiquity::MediaSilo::API::V3::Client::Requests

  # @see http://docs.mediasilo.com/v3.0/docs/create-asset
  class AssetCreate < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/assets'
    DEFAULT_PARAMETER_SEND_IN_VALUE = :body

    PARAMETERS = [
      { :name => :projectId, :required => true },
      :folderId,
      :title,
      :description,
      { :name => :sourceUrl, :required => true },
      :isPrivate
    ]

    def after_process_parameters
      arguments.delete(:folderId) if arguments[:folderId].to_s == '0'
    end

  end

end