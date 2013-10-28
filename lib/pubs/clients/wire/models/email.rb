class Email < ActiveRecord::Base
  
  attr_accessor :subject, :body
  
  validates_presence_of :from

  validate :check_content
  
  %w(subject body).each do |attribute|
    define_method attribute do
      read_locale(I18n.locale,attribute)
    end
  end
  
  after_commit :cache!
  
  before_save :set_key
  
  def self.fetch key
    Pubs.cache.get key
  end
  
  def as_json(options = {})
    super(options.merge({methods:[:subject,:body]}))
  end
  
  def read_locale locale, attribute
    (self.translations[locale.to_s] ||= {})[attribute] || 
    (self.translations[I18n.default_locale.to_s] ||= {})[attribute]
  end
  
  private
  
  def set_key
    self.key = self.subject.parameterize.underscore
  end
  
  def cache!
    Pubs.cache.set "wire:emails:#{self.key}", self.to_json
  end
  
  def check_content
    self.errors.add :subject, :blank unless self.translations[I18n.locale.to_s]["subject"].present?
    self.errors.add :body, :blank unless self.translations[I18n.locale.to_s]["body"].present?    
  end
  
end
