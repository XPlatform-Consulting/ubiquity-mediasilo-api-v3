module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetCopyToProject < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/projects/#{arguments[:destinationProjectId]}/assets/#{arguments[:assetId]}/copy'
    HTTP_SUCCESS_CODE = 204

    PARAMETERS = [
      { :name => :destinationProjectId, :required => true, :aliases => [ :projectid ] },
      { :name => :assetId, :required => true },
      :includeComments,
      :includeMetadata,
      :includeTags
    ]

  end

end