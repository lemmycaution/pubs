class Email < ActiveRecord::Base

  attr_accessor :locale, :subject, :text_body, :html_body

  # validates_presence_of :from

  validate :check_content

  %w(subject text_body html_body).each do |attribute|
    define_method attribute do
      read_locale(I18n.locale,attribute)
    end
  end

  # after_commit :cache!

  before_save :set_key

  # def self.fetch key
  #   Oj.load(Pubs.cache.get("wire:emails:#{key}") || "")
  # end

  def as_json(options = {})
    super(options.merge({methods:[:subject,:text_body,:html_body]}))
  end

  def read_locale locale, attribute
    (self.translations[locale.to_s] ||= {})[attribute] ||
    (self.translations[I18n.default_locale.to_s] ||= {})[attribute]
  end

  private

  def set_key
    self.key = self.subject.parameterize.underscore
  end

  # def cache!
  #   Pubs.cache.set "wire:emails:#{self.key}", Oj.dump(self.as_json)
  # end

  def check_content
    self.errors.add :subject, :blank unless self.translations[I18n.locale.to_s]["subject"].present?
    self.errors.add :html_body, :blank unless self.translations[I18n.locale.to_s]["html_body"].present?
    self.errors.add :text_body, :blank unless self.translations[I18n.locale.to_s]["text_body"].present?
  end

end
