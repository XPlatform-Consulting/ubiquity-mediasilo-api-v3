module Ubiquity::MediaSilo::API::V3::Client::Requests

  class ProjectCreate < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/projects'

    PARAMETERS = [
        { :name => :name, :required => true },
        :description,
    ]

  end

end