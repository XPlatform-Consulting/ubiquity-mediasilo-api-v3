module Ubiquity::MediaSilo::API::V3::Requests

  class AssetCreate < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/assets'

    PARAMETERS = [
      { :name => :projectId, :required => true },
      :folderId,
      :title,
      :description,
      { :name => :sourceUrl, :required => true },
      :isPrivate
    ]

    def post_process_arguments
      if options.fetch(:escape_source_url, true)
        _source_url = arguments[:sourceUrl]
        if options.fetch(:force_escape_source_url, false) or (_source_url == CGI.unescape(_source_url))
          arguments[:sourceUrl] = CGI.escape(_source_url)
        end
      end
    end

  end

end