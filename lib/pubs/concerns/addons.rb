require 'active_support/hash_with_indifferent_access'

module Pubs
  module Concerns
    module Addons

      extend ActiveSupport::Concern

      included do

        BASE_PRICE            = 3000
        BASE_DYNO_PRICE       = 3000

        [Forkable].each { |module_class|
          include module_class unless included_modules.include? module_class
        }

        before_create :post_addons
        before_update :put_addons
        validate :addons_validation

      end

      module ClassMethods

        def main_addon=addon
          @main_addon=addon
        end

        def main_addon
          @main_addon
        end

        def available_addons *addons
          @addons ||= Hash[YAML.load(File.read("#{Pubs.root}/db/addons.yml")).
          keep_if{ |a| a["name"].start_with?(*addons) }.map{|a| [a["name"],a]}].freeze
        end

        def addons
          @addons
        end

        def addon_plans group
          addons.reject{|key,addon| !addon['name'].start_with? group }.sort_by{|k,a| a["price"]["cents"].to_i }
        end

        def prices group
          i = 1
          self.addon_plans(group).map{|k,a| (a["price"]["cents"].to_i + (BASE_PRICE * ++i)) / 100 }
        end
      end

      def plan
        addons.try(:[], self.class.main_addon).try(:[],"plan")
      end

      def price
        return (BASE_PRICE + (dynos * BASE_DYNO_PRICE)) / 100 if Pubs.mock?
        ((addons.try(:[],self.class.main_addon).try(:[],"price").try(:[],"cents").to_i || 0) + BASE_PRICE) + (dynos * BASE_DYNO_PRICE) / 100
      end

      private

      def post_addons
        push "Creating addons"
        # return Pubs.mock(:addons) if Pubs.mock?

        self.addons.each do |name,addon|
          fetch_addon :post, addon
        end
      end

      def put_addons
        push "Updating addons"
        # return Pubs.mock(:addons) if Pubs.mock?

        self.addons.each do |name,addon|
          if self.addons_was.try(:[],addon['name']).try(:[],'plan') != self.addons[addon['name']]['plan']
            fetch_addon :put, addon
          else
            self.addons[addon['name']] = self.addons_was[addon['name']]
          end
        end
      end

      def fetch_addon action, addon
        begin
          self.addons[addon['name']].merge!(
            heroku.send(:"#{action}_addon", self.app['name'], "#{addon['name']}:#{addon['plan']}", addon['config'] || {}).body
          )

          if Pubs.mock?
            self.addons[addon['name']].merge!("message" => "HEROKU_POSTGRESQL_TEST_URL")
          end

          after_fetch_addon self.addons[addon['name']]
        rescue Exception => e
          if /use addons:add instead/ =~ e.try(:response).try(:body)
            fetch_addon :post, addon
          else
            puts "--> Error Database#fetch_addon #{e.inspect}"
            ap e.try(:response).try(:body)
            ap e.backtrace
            self.errors.add :addons, (e.try(:response).try(:body) || e.inspect)
            raise ActiveRecord::Rollback
          end
        end
      end


      def addons_validation
        addons.each do |key,addon|
          errors.add :addons, "Invalid Addon: #{addon["name"]}:#{addon["plan"]}" unless self.class.addons.map{|k,a| a["name"] }.include? "#{addon["name"]}:#{addon["plan"]}"
        end
      end

      def after_fetch_addon addon
      end

    end

  end
end
