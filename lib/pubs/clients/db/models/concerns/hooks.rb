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
        hooks.each do |api, uri|
          run_hook callback, api, uri
        end
      end
    end

    def run_hook event, api, uri, head = {}, query = {}

      # parse uri
      protocol, api_key, domain = uri.match(/(.+):\/\/(.+)?@(.+)/).try(:captures)

      return if protocol.nil? or domain.nil?

      # set api key header if protocol is wire
      if api == :wire
        return if api_key.nil?
        head["X-Api-Key"] = api_key
        protocol = domain.include?("herokuapp") ? "https" : "http"
        body = { action: event, context: self.as_json }
      else
        # query = { api_key: api_key }
        body = { api_key: api_key, action: event, unit: self.as_json }
      end
      url = "#{protocol}://#{domain}"

      # async http request, but we don't care the response for now
      http = client.post( url, { head: head,
        query: query, body: body
      })

      puts "RUNNING HOOK event: #{event} response: #{http}"

    end

    def client
      @client ||= Pubs::HTTP::Client.new
    end

  end
end

