module Ubiquity::MediaSilo::API::V3::Client::Requests

  class QuicklinkCreate < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/quicklinks'

    PARAMETERS = [
      { :name => :title, :required => true },
      :description,
      :assetIds,
      # :configuration,
      # :settings,
      # :expires,

      # :configuration_id,
      # :audience,
      # :playback,
      # :allow_download,
      # :allow_feedback,
      # :show_metadata,
      # :notify_email,
      # :include_directlink,
      # :password
    ]

    # def post_process_arguments
    #   settings = arguments.delete(:settings)
    #   audience = arguments.delete(:audience)
    #   playback = arguments.delete(:playback)
    #   allow_download = arguments.delete(:allow_download)
    #   allow_feedback = arguments.delete(:allow_feedback)
    #   show_metadata = arguments.delete(:show_metadata)
    #   notify_email = arguments.delete(:notify_email)
    #   include_directlink = arguments.delete(:include_directlink)
    #   password = arguments.delete(:password)
    #
    #   configuration = arguments[:configuration] || { }
    #   configuration_id = arguments[:configuration_id]
    #
    #   # TODO Symbolize Configuration Keys
    #   configuration[:id] ||= configuration_id || ''
    #
    #   settings ||= configuration[:settings] || { }
    #
    #   settings[:audience] = audience
    #
    # end

  end

end