require 'oj'
require 'pubs/concerns/roles'
require 'bcrypt'
require 'pubs/concerns/customer'

begin
  require "email_veracity"
rescue Exception => e
end

begin
  require 'app/mailers/invitation_mailer'
rescue Exception => e
end


class User < ActiveRecord::Base

  include Pubs::Concerns::Roles

  if defined?(Stripe)
    include Pubs::Concerns::Customer
  end

  REGISTRATION_ATTRIBUTES = %w(full_name email password password_confirmation organisation_id code)
  PROFILE_ATTRIBUTES = %w(full_name email password password_confirmation)
  AUTH_ATTRIBUTES = %w(email password)
  LIST_ATTRIBUTES = %w(id full_name email role organisation_id created_at sites)

  belongs_to :organisation

  has_secure_password

  after_initialize :set_meta

  before_validation :set_role, if: "new_record?"

  validates_presence_of   :full_name, :email, :organisation_id, :role
  validates_uniqueness_of :email, scope: :email
  validate :email_veracity

  # before_validation :generate_password, if: "new_record?"

  serialize :meta

  attr_accessor :code
  validate :valid_code, if: "new_record?"

  default_scope -> { where.not(role: "root") }
  scope :online, -> { where.not(sid: nil) }
  scope :by_org, -> (org_id) { where(organisation_id: org_id) }

  def self.authenticate! email, password
    if user = User.unscoped.find_by(email: email).try(:authenticate, password)
      user.reset_sid!
      user
    end
  end

  def self.decrypt! code
    if user = Pubs.cache.get("id:codes:#{code}")
      User.new(Oj.load(user).merge(code: code))
    end
  end

  def first_name
    full_name.split(" ").first
  end

  def role
    if role = self.read_attribute(:role)
      ActiveSupport::StringInquirer.new(role)
    end
  end

  def invite params
    invitee = User.new(email: params["email"], organisation_id: self.organisation.id, role: params["role"])
    InvitationMailer.invite self, invitee if invitee.validate_for_invitation(self)
    invitee
  end

  def reset_sid!
    self.update_attribute(:sid, Pubs.generate_key)
  end

  def validate_for_invitation inviter
    email_veracity
    errors.add(:email, :taken) if User.find_by(email: self.email)
    errors.add(:organisation_id, :blank) unless self.organisation.persisted?
    errors.add(:role, :blank) unless self.role.present?
    if self.role.present?
      errors.add(:role, :invalid) unless INVITABLE.include?(self.role)
      errors.add(:role, :invalid) unless INVITABLE.include?(self.role)
      errors.add(:role, :invalid) if self > inviter
    end
    errors.empty?
  end

  def generate_code
    self.organisation.generate_code_for_user(self) if self.role.present?
  end

  private

  def set_meta
    self.meta ||= {}
  end

  def email_veracity
    errors.add(:email, :invalid) unless EmailVeracity::Address.new(self.email).valid?
  end

  def valid_code
    errors.add(:code, :invalid) if self.organisation.nil? or self.organisation.can_accept_user(self).nil?
  end

  def set_role
    self.role = User.decrypt!(self.code).try(:[],:role)
  end

  # def generate_password
  #   self.password = self.password_confirmation = Pubs.generate_key
  # end

end
