module Ubiquity::MediaSilo::API::V3::Requests

 class  AssetDelete < BaseRequest

  HTTP_METHOD = :delete
  HTTP_PATH = '/assets/#{arguments[:assetId]}'

  PARAMETERS = [
    { :name => :assetId, :aliases => [ :id ], :required => true }
  ]

 end

end