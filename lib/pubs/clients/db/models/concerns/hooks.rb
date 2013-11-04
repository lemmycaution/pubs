require 'active_support/concern'
require 'pubs/http/client'
require 'pubs/endpoints/helpers/template'
module Concerns

  module Hooks

    extend ActiveSupport::Concern

    include Pubs::Endpoints::Helpers::Template::Helpers


    included do
      before_create do
        run_hooks :before_create if has_model?
      end
      before_update do
        run_hooks :before_update if has_model?
      end
      before_destroy do
        run_hooks :before_destroy if has_model?
      end

      after_create do
        run_hooks :after_create if has_model?
      end
      after_update do
        run_hooks :after_update if has_model?
      end
      after_destroy do
        run_hooks :after_destroy if has_model?
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
        body = { api_key: api_key, event: event, unit: self.as_json }
      end
      url = "#{protocol}://#{domain}"

      # async http request, but we don't care the response for now
      result = Pubs::HTTP::Client.new.post( url, { head: head,
        query: query, body: body
      })
      ap result.response

    end

  end
end

