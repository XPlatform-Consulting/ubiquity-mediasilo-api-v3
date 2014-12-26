module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetMoveToProject < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/projects/#{arguments[:destinationProjectId]}/assets/#{arguments[:assetId]}/move'
    HTTP_SUCCESS_CODE = 204

    PARAMETERS = [
      { :name => :destinationProjectId, :required => true, :aliases => [ :projectid ] },
      { :name => :assetId, :required => true },
    ]

  end

end