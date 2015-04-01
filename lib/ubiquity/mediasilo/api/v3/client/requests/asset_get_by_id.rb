module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetGetById < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/assets/#{arguments[:asset_id]}'

    PARAMETERS = [
      { :name => :asset_id, :aliases => [ :id ], :send_in => :path, :required => true },
    ]

  end

end