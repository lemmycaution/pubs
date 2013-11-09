require 'bcrypt'
require 'oj'

class Organisation < ActiveRecord::Base

  CODE_EXPIRE_TTL = 7200

  has_many :users, dependent: :delete_all

  validates_presence_of   :name
  validates_uniqueness_of :name

  after_create :create_root_user
  before_destroy :destroy_root_user

  attr_reader :root

  def root
    @root ||= User.unscoped.find_by(root_params.merge({organisation_id: self.id}))
  end

  def can_accept_user(user)
    BCrypt::Password.new(user.code) == code_chip(user) rescue nil
  end

  def generate_code_for_user(user)
    code = BCrypt::Password.create code_chip(user)

    if Pubs.cache.get("id:codes:#{code}").nil?
      Pubs.cache.set("id:codes:#{code}", Oj.dump(user.as_json), CODE_EXPIRE_TTL)
    end

    code
  end

  def code_chip(user)
    "#{user.email}|#{name}"
  end

  private

  def create_root_user
    root = self.users.find_or_initialize_by(root_params)

    root.code = self.generate_code_for_user root
    root.password_confirmation = root.password = Pubs.generate_key
    root.save!
  end

  def destroy_root_user
    self.root.try(:destroy)
  end

  def root_params
    @root_params = {
    full_name: Pubs::Concerns::Roles::TYPES.first,
    email: "#{Pubs::Concerns::Roles::TYPES.first}.#{name.parameterize}@pubs.io",
    role: Pubs::Concerns::Roles::TYPES.first}
  end
end
