require "active_support/core_ext"
require "pubs/core_ext/string_boolean"
require 'heroku/api'

module Pubs
  module Concerns
    module HerokuApi
  
      extend ActiveSupport::Concern
      
      def heroku 
        @heroku ||= ::Heroku::API.new(api_key: ENV['HEROKU_API_KEY'], mock: Pubs.mock?)
      end
  
    end

  end
end