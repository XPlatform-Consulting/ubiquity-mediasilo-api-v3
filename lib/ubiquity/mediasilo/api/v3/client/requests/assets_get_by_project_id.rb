module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetsGetByProjectId < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/projects/#{arguments[:projectId]}/assets'

    PARAMETERS = [
      { :name => :projectId, :aliases => [ :id ], :required => true },
    ]

  end

end