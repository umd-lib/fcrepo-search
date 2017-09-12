# frozen_string_literal: true
class CatalogController < ApplicationController
  include Blacklight::Catalog
  before_action :make_current_query_accessible, only: [:show, :index]

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    # The fq parameter is conditionally overriden in app/models/search_builder.rb
    config.default_solr_params = {
      rows: 10,
      fq: ['is_pcdm:true', '{!collapse field=extracted_text_source nullPolicy=expand}'],
      expand: 'true'
    }

    # solr path which will be added to solr base url before the other solr params.
    config.solr_path = 'search'
    config.document_solr_path = 'document'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see
    ## SearchHelper#solr_doc_params) or parameters included in the Blacklight-jetty document requestHandler.
    #
    # config.default_document_solr_params = {
    #  qt: 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # fl: '*',
    #  # rows: 1,
    #  # q: '{!term f=id v=$id}'
    # }

    # solr field configuration for search results/index views
    config.index.title_field = 'display_title'

    # solr field configuration for document/show views
    config.show.title_field = 'display_title'
    # config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set
    #  of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation
    # (note: It is case sensitive when searching values)

    config.add_facet_field 'author_not_tokenized', label: 'Author', limit: 10
    config.add_facet_field 'type', label: 'Type', limit: 10
    config.add_facet_field 'object_type_not_tokenized', label: 'Object Type', limit: 10
    config.add_facet_field 'component_not_tokenized', label: 'Component', limit: 10
    config.add_facet_field 'rdf_type', label: 'RDF Type', limit: 10
    # config.add_facet_field 'pub_date', label: 'Publication Year', single: true
    # config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    # config.add_facet_field 'language_facet', label: 'Language', limit: true
    # config.add_facet_field 'lc_1letter_facet', label: 'Call Number'
    # config.add_facet_field 'subject_geo_facet', label: 'Region'
    # config.add_facet_field 'subject_era_facet', label: 'Era'

    # config.add_facet_field 'example_pivot_field', label: 'Pivot Field', pivot: %w(format language_facet)

    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', query: {
    #  years_5: { label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5} TO *]" },
    #  years_10: { label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10} TO *]" },
    #  years_25: { label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25} TO *]" }
    # }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'id', label: 'Annotation', helper_method: :link_to_document_view, if: :is_annotation?
    config.add_index_field 'object_type', label: 'Object Type'
    config.add_index_field 'component', label: 'Component'
    config.add_index_field 'author', label: 'Author'
    config.add_index_field 'extracted_text', label: 'OCR', highlight: true, helper_method: :format_extracted_text, solr_params: { 'hl.fragsize' => 500 }, if: :is_annotation?
    config.add_index_field 'created_by', label: 'Created By'
    config.add_index_field 'created', label: 'Created'
    config.add_index_field 'last_modified', label: 'Last Modified'

    # Have BL send the most basic highlighting parameters for you
    config.add_field_configuration_to_solr_request!

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'display_title', label: 'Title'
    config.add_show_field 'author', label: 'Author'
    config.add_show_field 'type', label: 'Type'
    config.add_show_field 'rdf_type', label: 'RDF Type', helper_method: :rdf_type_list
    config.add_show_field 'date', label: 'Date'
    config.add_show_field 'pcdm_collection', label: 'Collection', helper_method: :collection_from_subquery
    config.add_show_field 'pcdm_member_of', label: 'Member Of', helper_method: :parent_from_subquery
    config.add_show_field 'pcdm_members', label: 'Members', helper_method: :members_from_subquery
    config.add_show_field 'pcdm_related_object_of', label: 'Related To', helper_method: :related_object_of_from_subquery
    # rubocop:disable Metrics/LineLength
    config.add_show_field 'pcdm_related_objects', label: 'Related Objects', helper_method: :related_objects_from_subquery
    # rubocop:enable Metrics/LineLength
    config.add_show_field 'pcdm_file_of', label: 'File Of', helper_method: :file_parent_from_subquery
    config.add_show_field 'pcdm_files', label: 'Files', helper_method: :files_from_subquery
    config.add_show_field 'object_type', label: 'Object Type'
    config.add_show_field 'component', label: 'Component'
    config.add_show_field 'issue_volume', label: 'Volume'
    config.add_show_field 'issue_issue', label: 'Issue Number'
    config.add_show_field 'issue_edition', label: 'Edition'
    config.add_show_field 'issue_lccn', label: 'LCCN'
    config.add_show_field 'page_number', label: 'Number'
    config.add_show_field 'page_reel', label: 'Reel'
    config.add_show_field 'page_issue', label: 'Issue'
    config.add_show_field 'page_sequence', label: 'Sequence'
    config.add_show_field 'annotation_source', label: 'Pages', helper_method: :annotation_source_from_subquery
    config.add_show_field 'size', label: 'Size'
    config.add_show_field 'mime_type', label: 'Mime Type'
    config.add_show_field 'digest', label: 'Digest'
    config.add_show_field 'created_by', label: 'Created By'
    config.add_show_field 'created', label: 'Created'
    config.add_show_field 'last_modified', label: 'Last Modified'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, display_title asc', label: 'relevance'
    # config.add_sort_field 'pub_date_sort desc, title_sort asc', label: 'year'
    # config.add_sort_field 'author_sort asc, title_sort asc', label: 'author'
    # config.add_sort_field 'title_sort asc, pub_date_sort desc', label: 'title'
    config.add_sort_field 'display_title asc', label: 'title'
    config.add_sort_field 'created asc', label: 'created (oldest to newest)'
    config.add_sort_field 'created desc', label: 'created (newest to oldest)'
    config.add_sort_field 'last_modified asc', label: 'last modified (oldest to newest)'
    config.add_sort_field 'last_modified desc', label: 'last modified (newest to oldest)'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end

  private

    def make_current_query_accessible
      @current_query = params[:q]
    end

    def is_annotation?(field, document)
      document[:rdf_type].include?('oa:Annotation')
    end
end
