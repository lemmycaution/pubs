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
      after_initialize :clear_validators
    end

    module ClassMethods
      # def dynamic_validators
      #   @dynamic_validators ||= []
      # end
    end

    def clear_validators
      self.class.instance_exec {
        reset_callbacks(:validate)
      }

    end

    def validate_data

      # puts "MODEL #{model.as_json}"

      # puts "MODEL VALS #{model.validations}"

      model.validations.each do |field, rules|

        # validators = self.class.validators_on(field)

        # puts "ANANIN!!! #{field}"

        rules.each do |kind, val|
          # hex = OpenSSL::Digest::MD5.hexdigest("#{field}:{#{val}}")
          # unless self.class.dynamic_validators.include? hex
            # if validators.empty? || !validators.map(&:kind).include?(kind)
            self.class.instance_exec(field, val) { |field, val|
              validates field, eval("{#{val}}")
            }
            # self.class.dynamic_validators << hex
            # end
          # end

        end
      end



    end



  end
end