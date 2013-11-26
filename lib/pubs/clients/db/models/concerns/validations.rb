require 'active_support/concern'
require 'email_veracity'
module Concerns
  module Validations

    extend ActiveSupport::Concern

    class VeracityValidator < ActiveModel::Validator
      def validate(record)
        t = record.model.translations[I18n.locale].try(:[],:errors).try(:[],:email).try(:[],:veracity) || :invalid
        record.errors.add(:email, t) unless EmailVeracity::Address.new(record.email).valid?
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
      translations = model.translations
      model.validations.each do |field, rules|

        # validators = self.class.validators_on(field)

        # puts "ANANIN!!! #{field}"

        rules.each do |kind, val|
          # hex = OpenSSL::Digest::MD5.hexdigest("#{field}:{#{val}}")
          # unless self.class.dynamic_validators.include? hex
            # if validators.empty? || !validators.map(&:kind).include?(kind)
            self.class.instance_exec(field, val) { |field, val|
              ops = eval("{#{val}}")
              if t = translations[I18n.locale].try(:[],:errors).try(:[],field).try(:[],kind)
                validates field, {kind => ops.try(:merge, {message: t})}
              else
                validates field, {kind => ops}
              end
            }
            # self.class.dynamic_validators << hex
            # end
          # end

        end
      end



    end



  end
end