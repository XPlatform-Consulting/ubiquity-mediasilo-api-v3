module Ubiquity::MediaSilo::API::V3::Client::Requests

  # @see http://docs.mediasilo.com/v3.0/docs/batch-overview
  class Batch < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = 'batch'
    HTTP_SUCCESS_CODE = 200

    PARAMETERS = [
      { :name => :requests, :send_in => :body, :send_key => false }
    ]

    def body
      @body ||= arguments[:requests]
    end

  end

end