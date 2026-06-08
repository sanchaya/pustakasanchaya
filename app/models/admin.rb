require 'bcrypt'
require 'securerandom'

class Admin
  attr_accessor :id, :email, :name, :role, :created_at, :last_login, :active

  def self.find(id)
    user = AdminUser.find_by(id: id)
    return nil unless user
    from_record(user)
  end

  def self.find_by_email(email)
    user = AdminUser.find_by(email: email)
    return nil unless user
    from_record(user)
  end

  def self.authenticate(email, password)
    user = AdminUser.find_by(email: email)
    return nil unless user && user.active
    if BCrypt::Password.new(user.password_hash) == password
      admin = from_record(user)
      admin.update_last_login
      admin
    else
      nil
    end
  rescue BCrypt::Errors::InvalidHash
    nil
  end

  def self.all
    AdminUser.all.map { |u| from_record(u) }
  end

  def self.list_all
    AdminUser.all.map do |u|
      {
        'id' => u.id.to_s,
        'name' => u.name,
        'email' => u.email,
        'role' => u.role,
        'active' => u.active,
        'created_at' => u.created_at&.iso8601,
        'last_login' => u.last_login&.iso8601
      }
    end
  end

  def self.email_taken?(email, exclude_id = nil)
    scope = AdminUser.where(email: email)
    scope = scope.where('id != ?', exclude_id) if exclude_id
    scope.exists?
  end

  def self.create_invite(email, role = 'editor')
    if AdminUser.exists?(email: email) || Invite.exists?(email: email, used: false)
      return { error: 'Email already registered or invited' }
    end

    token = SecureRandom.hex(32)
    invite = Invite.create!(email: email, role: role, token: token, used: false)

    { success: true, token: token, invite: invite.attributes }
  end

  def self.pending_invites
    Invite.unused.map(&:attributes)
  end

  def self.find_invite(token)
    invite = Invite.find_by(token: token, used: false)
    return nil unless invite
    invite.attributes
  end

  def self.accept_invite(token, name, password)
    invite = Invite.find_by(token: token, used: false)
    return { error: 'Invalid or expired invite' } unless invite

    password_hash = BCrypt::Password.create(password)
    user = AdminUser.create!(
      email: invite.email,
      name: name,
      password_hash: password_hash,
      role: invite.role,
      active: true
    )
    invite.update!(used: true, used_at: Time.now)

    { success: true, admin: from_record(user) }
  end

  def self.revoke_invite(token)
    invite = Invite.find_by(token: token)
    return false unless invite
    invite.destroy
    true
  end

  def update_password(new_password)
    user = AdminUser.find_by(id: id)
    return false unless user
    user.update!(password_hash: BCrypt::Password.create(new_password))
    true
  end

  def update_last_login
    AdminUser.where(id: id).update_all(last_login: Time.now)
    true
  end

  def super_admin?
    role == 'super_admin'
  end

  def editor?
    role == 'editor' || super_admin?
  end

  def deactivate
    user = AdminUser.find_by(id: id)
    return false unless user
    user.update!(active: false)
    self.active = false
    true
  end

  def update_profile(name, email = nil)
    user = AdminUser.find_by(id: id)
    return false unless user
    attrs = { name: name }
    attrs[:email] = email if email && email != self.email
    user.update!(attrs)
    self.name = name
    self.email = email if email
    true
  end

  private

  def self.from_record(user)
    admin = new
    admin.id = user.id.to_s
    admin.email = user.email
    admin.name = user.name
    admin.role = user.role
    admin.created_at = user.created_at&.iso8601
    admin.last_login = user.last_login&.iso8601
    admin.active = user.active
    admin
  end
end
