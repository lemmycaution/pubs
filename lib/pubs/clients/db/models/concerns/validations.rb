require 'active_support/concern'
require 'email_veracity'
module Concerns
  module Validations

    extend ActiveSupport::Concern

    class VeracityValidator < ActiveModel::Validator
      def validate(record)
        record.errors.add(:email, :invalid) unless EmailVeracity::Address.new(record.email).valid?
      end
    end

    included do
      before_validation :validate_data, if: :has_model?
    end

    module ClassMethods
      def dynamic_validators
        @dynamic_validators ||= []
      end
    end

    def validate_data

      model.validations.each do |field, rules|

        # validators = self.class.validators_on(field)

        rules.each do |kind, val|
          hex = OpenSSL::Digest::MD5.hexdigest("{#{val}}")
          unless self.class.dynamic_validators.include? hex
            # if validators.empty? || !validators.map(&:kind).include?(kind)
            self.class.validates(field, eval("{#{val}}"))
            self.class.dynamic_validators << hex
            # end
          end

        end
      end



    end



  end
end