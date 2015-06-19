module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetsGetByFolderId < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/folders/#{arguments[:folderId]}/assets'

    PARAMETERS = [
      { :name => :folderId, :aliases => [ :id ], :required => true },
    ]

  end

end