module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetGetById < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/assets/#{arguments[:assetId]}'

    PARAMETERS = [
      { :name => :asset_id, :aliases => [ :id ], :required => true },
    ]

  end

end