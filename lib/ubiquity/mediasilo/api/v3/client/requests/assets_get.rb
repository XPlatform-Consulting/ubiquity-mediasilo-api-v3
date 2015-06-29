module Ubiquity::MediaSilo::API::V3::Client::Requests

  class AssetsGet < BaseRequest

    HTTP_METHOD = :get
    HTTP_PATH = '/assets'

    PARAMETERS = [
      # { :name => :_pageSize, :default_value => 250 },
      :_pageSize,
      :_page,
      :_sortBy,
      :_sort,

      :approvalstatus,
      :averagerating,
      :comments,
      :datecreated,
      :datemodified,
      :description,
      :duration,
      :filename,
      :folderid,
      :hasapprovals,
      :hascomments,
      :hasrating,
      :hastranscript,
      :height,
      :metadatakeys,
      :metadatakeys_exact,
      :metadatamatch,
      :metadatavalues,
      :metadatavalues_exact,
      :projectid,
      :rating,
      :size,
      :tags,
      :title,
      :transcript,
      :transcriptstatus,
      :type,
      # { :name => :type, :default_value => '{"in":"video,image,document,archive,audio"}' },
      :uploaduser,
      :width,
    ]

  end

end