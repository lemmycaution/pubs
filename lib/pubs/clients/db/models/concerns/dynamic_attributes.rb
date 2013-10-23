module Concerns
  module DynamicAttributes
    
    extend ActiveSupport::Concern
    
    included do
      after_initialize :set_accessors
    end
    
    def self.store_accessor(store_attribute, *keys, model)
      keys = keys.flatten

      _store_accessors_module.module_eval do
        keys.each do |key|
          define_method("#{key}=") do |value|
            write_store_attribute(store_attribute, key, value)
          end

          define_method(key) do
            read_store_attribute(store_attribute, key)
          end
        end
      end

      self.stored_attributes[model] ||= {}

      self.stored_attributes[model][store_attribute] ||= []
      self.stored_attributes[model][store_attribute] |= keys
    end  


    def assign_attributes(new_attributes)
      return if new_attributes.blank?

      attributes                  = new_attributes.stringify_keys
      multi_parameter_attributes  = []
      nested_parameter_attributes = []

      attributes = sanitize_for_mass_assignment(attributes)

      attributes.each do |k, v|
        
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        elsif v.is_a?(Hash)
          nested_parameter_attributes << [ k, v ]
        # the key trick!  
        elsif self.model.try(:key) == k
          self.key = v  
        else
          _assign_attribute(k, v)
        end
      end

      assign_nested_parameter_attributes(nested_parameter_attributes) unless nested_parameter_attributes.empty?
      assign_multiparameter_attributes(multi_parameter_attributes) unless multi_parameter_attributes.empty?
    end
  
    private

  
    def set_accessors

      if k = model.try(:key)
        self.class.class_eval <<-CODE
        def #{k}; self.key end
        def #{k}=val; self.key=val end
        CODE
      end
      
      self.data ||= {}
        
      accessors = self.data.keys + (model.try(:persistents) || [])
      self.class.store_accessor :data, *accessors, model.try(:name) || "Unit"
      
      self.class.send :attr_accessor, *model.try(:stubs)
    
    end
  end
end