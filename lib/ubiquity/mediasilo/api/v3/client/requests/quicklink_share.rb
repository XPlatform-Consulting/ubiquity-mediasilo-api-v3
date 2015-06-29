module Ubiquity::MediaSilo::API::V3::Client::Requests

  class QuicklinkShare < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/shares'

    PARAMETERS = [
      { :name => :targetObjectId, :required => true },
      :emailShare,
      :subject,
      :message,
      :audience
    ]

    def post_process_arguments
    end

  end

end