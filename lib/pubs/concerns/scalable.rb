require 'pubs/concerns/forkable'

module Pubs
  module Concerns
    module Scalable

      extend ActiveSupport::Concern

      included do

        [Forkable].each { |module_class|
          include module_class unless included_modules.include? module_class
        }

      end

      def dynos
        @dynos ||= self.ps
      end

      def dynos=count
        post_ps_scale(count)
        @dynos = count
      end

      def ps
        puts "APP NAME #{self.app[:name]}"
        heroku.get_ps(self.app[:name]).body.keep_if{|p|
          p["process"].start_with?("web")
        }.sum{|p| p.try(:[],"size") || 1}
      end

      def post_ps_scale count, type = "web"
        heroku.post_ps_scale(self.app[:name], type, count)
      end

    end

  end
end