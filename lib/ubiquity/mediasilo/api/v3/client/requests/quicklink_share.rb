module Ubiquity::MediaSilo::API::V3::Client::Requests

  class QuicklinkShare < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/shares'
    DEFAULT_PARAMETER_SEND_IN_VALUE = :body

    PARAMETERS = [
      { :name => :targetObjectId, :required => true },
      :emailShare,
      :subject,
      :message,
      :audience
    ]

    def post_process_arguments
      _email_share = arguments[:emailShare]
      _email_share ||= { }
      _audience = arguments[:audience] || _email_share[:audience] || _email_share['audience'] || [ ]
      _subject = arguments[:subject] || _email_share[:subject] || _email_share['subject']
      _message = arguments[:message] || _email_share[:message] || _email_share['message']
      _email_share[:audience] ||= _audience
      _email_share[:subject] ||= _subject if _subject
      _email_share[:message] ||= _message if _message

      arguments[:emailShare] = _email_share
    end

  end

end