require "insights/api/common/graphql"

module Api
  module V1x0
    class GraphqlController < ApplicationController
      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema(request, overlay)
        variables = ::Insights::API::Common::GraphQL.ensure_hash(params[:variables])
        result = graphql_api_schema.execute(
          params[:query],
          :variables => variables
        )
        render :json => result
      end

      def overlay
        {
          "^.*$" => {
            "base_query" => lambda do |model_class, _ctx|
              "::Api::V1x0::#{model_class.to_s.pluralize}Controller".constantize.new.send(:index_scope, model_class.all)
            end
          }
        }
      end
    end
  end
end
