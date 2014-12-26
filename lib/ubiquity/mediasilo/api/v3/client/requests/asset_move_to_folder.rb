module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetMoveToFolder < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/folders/#{arguments[:destinationFolderId]}/assets/#{arguments[:assetId]}/move'
    HTTP_SUCCESS_CODE = 204

    PARAMETERS = [
      { :name => :destinationFolderId, :required => true, :aliases => [ :folderid ] },
      { :name => :assetId, :required => true },
    ]

  end

end