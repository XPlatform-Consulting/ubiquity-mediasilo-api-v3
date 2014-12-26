module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetsGetByFolderId < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/assets/#{arguments[:folderId]}'

    PARAMETERS = [
      { :name => :folderId, :aliases => [ :id ], :required => true },
    ]

  end

end