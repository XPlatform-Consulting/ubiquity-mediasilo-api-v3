module Ubiquity::MediaSilo::API::V3::Client::Requests

 class  AssetDelete < BaseRequest

  HTTP_METHOD = :delete
  HTTP_PATH = '/assets/#{arguments[:assetId]}'
  HTTP_SUCCESS_CODE = 204

  PARAMETERS = [
    { :name => :assetId, :aliases => [ :id ], :required => true }
  ]

 end

end