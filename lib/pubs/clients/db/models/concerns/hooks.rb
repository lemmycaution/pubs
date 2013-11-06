require 'active_support/concern'
require 'pubs/http/client'
require 'pubs/endpoints/helpers/template'

module Concerns

  module Hooks

    CALLBACKS = %w(before_create before_update before_destroy after_create after_update after_destroy).freeze

    extend ActiveSupport::Concern

    include Pubs::Endpoints::Helpers::Template::Helpers

    included do

      CALLBACKS.each do |callback|
        class_eval <<-CODE
        #{callback} do
          run_hooks :#{callback} if has_model?
        end
        CODE
      end

    end

    def run_hooks(callback)
      # get the hooks hash for a callback
      if hooks = self.model.hooks[callback]
        # run every single action
        hooks.each do |api, params|
          run_hook callback, api, params
        end
      end
    end

    def run_hook event, api, params

      head  = params[:head] || {}
      query = params[:query] || {}
      uri   = params[:uri]

      # parse uri
      protocol, api_key, domain = uri.match(/(.+):\/\/(.+)?@(.+)/).try(:captures)

      return if protocol.nil? or domain.nil?

      # set api key header if protocol is wire
      if api == :wire
        return if api_key.nil?
        head["X-Api-Key"] = api_key
        protocol = domain.include?("herokuapp") ? "https" : "http"
        body = { action: event, job_id: self.id, context: {data: self.as_json} }
      else
        body = { action: event, unit: self.as_json }
      end
      url = "#{protocol}://#{domain}"

      # async http request, but we don't care the response for now
      http = client.post( url, { head: head, query: query, body: body} )

    end

    def client
      @client ||= Pubs::HTTP::Client.new
    end

  end
end

