require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/hash_with_indifferent_access'
module Pubs
  module Concerns
    module Roles
  
      ALL = "all".freeze
      TYPES = %w(root admin manager developer editor).freeze
      INVITABLE = %w(admin manager developer editor).freeze
      
      extend ActiveSupport::Concern
  
      module ClassMethods
        def abilities
          @abilities ||= ActiveSupport::HashWithIndifferentAccess.new(Pubs.config(:abilities)).freeze
        end
      end
  
      def > user
        TYPES.index(self.role) < TYPES.index(user.role)
      end
  
      def < user
        TYPES.index(self.role) > TYPES.index(user.role)    
      end
  
      def >= user
        TYPES.index(self.role) <= TYPES.index(user.role)
      end
  
      def <= user
        TYPES.index(self.role) >= TYPES.index(user.role)    
      end
  
      def can? action, klass
        ability = able?(:can, action)
        !cannot?(action,klass) and (can_manage_all? or can_manage?(klass) or ability == ALL or ability.try(:include?,klass))
      end
  
      def cannot? action, klass
        able?(:cannot,action).try(:include?,klass)
      end
  
      def able? can_or_not, action
        abilities.try(:[],self.role.to_sym).try(:[],can_or_not).try(:[],action)
      end
  
      def can_manage? klass
        able?(:can,:manage).try(:include?, klass)
      end
  
      def can_manage_all?
        can_manage? ALL
      end
    
      def abilities
        self.class.abilities
      end

    end
  end
end