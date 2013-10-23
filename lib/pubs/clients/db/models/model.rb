require 'pubs/clients/db/models/concerns/json_keys_symbolizer'

class Model < ActiveRecord::Base
  include Concerns::JsonKeysSymbolizer
  
  attr_symbolize :properties,:validations,:hooks,:settings

  attr_accessor :code
  
  has_many :units
  def model; self end

  validates_presence_of :name, :key, :properties
  validates_uniqueness_of :name
  
  before_validation :normalize_fields
  
  def code
    self.dup.to_json(except: [:id,:created_at,:updated_at,:units_count])
  end
  
  def rep
    as_json(only: [:id,:name,:key,:created_at,:updated_at],methods:[:code])
  end
  
  def stubs
    properties.select{ |k,v| v == 'stub' }.keys
  end
  
  def persistents
    properties.select{ |k,v| v != 'stub' }.keys
  end  
  
  private
  
  def normalize_fields
    self.name = self.name.parameterize.underscore.classify if /\s/ =~ self.name
    self.key  = self.key.parameterize.underscore 
  end
  
end
