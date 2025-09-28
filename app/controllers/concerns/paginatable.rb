module Paginatable
  extend ActiveSupport::Concern

  private

  def paginate_collection(collection, serializer_class = nil)
    paginated_collection = collection
      .page(params[:page])
      .per(params[:per_page] || 20)

    response_data = {
      pagination: {
        current_page: paginated_collection.current_page,
        per_page: paginated_collection.limit_value,
        total_pages: paginated_collection.total_pages,
        total_count: paginated_collection.total_count
      }
    }

    if serializer_class
      response_data[:data] = ActiveModel::Serializer::CollectionSerializer.new(
        paginated_collection, 
        serializer: serializer_class
      )
    else
      response_data[:data] = paginated_collection
    end

    response_data
  end
end