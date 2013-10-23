require 'pubs/clients/db/models/concerns/validations'
require 'pubs/clients/db/models/concerns/dynamic_attributes'
require 'pubs/clients/db/models/concerns/hooks'
require 'pubs/clients/db/models/model'
require 'pg_search'

class Unit < ActiveRecord::Base
    
  include Concerns::DynamicAttributes    
  include Concerns::Validations
  include Concerns::Hooks

  belongs_to :model, counter_cache: true

  validates_presence_of   :key
  validates_uniqueness_of :key
  before_save             :clear_stubs, if: "has_model?"
  before_save             :ensure_key_not_changed
  
  def has_model?
    self.model.present?
  end

  def clear_stubs
    data.each do |k,v|
      data.delete(k) if model.stubs.include? k.to_sym 
    end
  end

  def ensure_key_not_changed
    errors.add(:key, :read_only) if self.key_was != self.key
  end
  
  # search
  
  include PgSearch
    
  pg_search_scope :data_search, :against => [:key,:data], :using => {
    :tsearch => {:prefix => true, :any_word => true, :ignoring => :accents}
  }
  
  pg_search_scope :tag_search, :against => :tags, :using => {
    :tsearch => {:prefix => true, :any_word => true, :ignoring => :accents}
  }  

  def self.search(against,query)
    self.send :"#{against}_search", query
  end
  
  

end
