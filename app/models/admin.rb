require 'json'
require 'bcrypt'
require 'securerandom'

class Admin
  @@admins_cache = nil
  @@invites_cache = nil

  attr_accessor :id, :email, :name, :role, :created_at, :last_login, :active

  def self.admin_users_path
    Rails.root.join('db', 'admin_users.json')
  end

  def self.load_admin_data
    return if @@admins_cache && @@invites_cache
    if File.exist?(admin_users_path)
      data = JSON.parse(File.read(admin_users_path))
      @@admins_cache = data['admins'] || []
      @@invites_cache = data['invites'] || []
    else
      @@admins_cache = []
      @@invites_cache = []
    end
  end

  def self.save_admin_data
    data = {
      'admins' => @@admins_cache,
      'invites' => @@invites_cache
    }
    File.write(admin_users_path, JSON.pretty_generate(data))
  end

  # Find admin by email
  def self.find_by_email(email)
    load_admin_data
    admin_data = @@admins_cache.find { |a| a['email'] == email }
    return nil unless admin_data
    
    admin = new
    admin.id = admin_data['id']
    admin.email = admin_data['email']
    admin.name = admin_data['name']
    admin.role = admin_data['role']
    admin.created_at = admin_data['created_at']
    admin.last_login = admin_data['last_login']
    admin.active = admin_data['active']
    admin
  end

  # Find admin by ID
  def self.find(id)
    load_admin_data
    admin_data = @@admins_cache.find { |a| a['id'] == id }
    return nil unless admin_data
    
    admin = new
    admin.id = admin_data['id']
    admin.email = admin_data['email']
    admin.name = admin_data['name']
    admin.role = admin_data['role']
    admin.created_at = admin_data['created_at']
    admin.last_login = admin_data['last_login']
    admin.active = admin_data['active']
    admin
  end

  # Authenticate with email and password
  def self.authenticate(email, password)
    admin = find_by_email(email)
    return nil unless admin && admin.active

    # Find the actual password hash
    load_admin_data
    admin_data = @@admins_cache.find { |a| a['email'] == email }
    return nil unless admin_data

    # Use BCrypt to compare passwords
    if BCrypt::Password.new(admin_data['password_hash']) == password
      admin.update_last_login
      admin
    else
      nil
    end
  rescue BCrypt::Errors::InvalidHash
    nil
  end

  # Generate invite token
  def self.create_invite(email, role = 'editor')
    load_admin_data
    
    # Check if already invited or registered
    if @@admins_cache.any? { |a| a['email'] == email } ||
       @@invites_cache.any? { |i| i['email'] == email }
      return { error: 'Email already registered or invited' }
    end

    token = SecureRandom.hex(32)
    invite = {
      'token' => token,
      'email' => email,
      'role' => role,
      'created_at' => Time.now.iso8601,
      'used' => false
    }

    @@invites_cache << invite
    save_admin_data

    { success: true, token: token, invite: invite }
  end

  # Get invite by token
  def self.find_invite(token)
    load_admin_data
    @@invites_cache.find { |i| i['token'] == token && !i['used'] }
  end

  # Accept invite and create admin user
  def self.accept_invite(token, name, password)
    invite = find_invite(token)
    return { error: 'Invalid or expired invite' } unless invite

    load_admin_data

    # Hash password with BCrypt
    password_hash = BCrypt::Password.create(password)

    # Create new admin
    admin_id = "admin_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
    new_admin = {
      'id' => admin_id,
      'email' => invite['email'],
      'password_hash' => password_hash,
      'name' => name,
      'role' => invite['role'],
      'created_at' => Time.now.iso8601,
      'last_login' => nil,
      'active' => true
    }

    @@admins_cache << new_admin
    invite['used'] = true
    invite['used_at'] = Time.now.iso8601

    save_admin_data

    { success: true, admin: new_admin }
  end

  # Update password
  def update_password(new_password)
    load_admin_data
    admin_data = @@admins_cache.find { |a| a['id'] == self.id }
    return false unless admin_data

    admin_data['password_hash'] = BCrypt::Password.create(new_password)
    self.class.save_admin_data
    true
  end

  # Update last login
  def update_last_login
    self.class.load_admin_data
    admin_data = @@admins_cache.find { |a| a['id'] == self.id }
    return false unless admin_data

    admin_data['last_login'] = Time.now.iso8601
    self.class.save_admin_data
    true
  end

  # Check if admin is super admin
  def super_admin?
    role == 'super_admin'
  end

  # Check if admin is editor
  def editor?
    role == 'editor' || super_admin?
  end

  # Get all admins
  def self.all
    load_admin_data
    @@admins_cache.map do |admin_data|
      admin = new
      admin.id = admin_data['id']
      admin.email = admin_data['email']
      admin.name = admin_data['name']
      admin.role = admin_data['role']
      admin.created_at = admin_data['created_at']
      admin.last_login = admin_data['last_login']
      admin.active = admin_data['active']
      admin
    end
  end

  # Get all pending invites
  def self.pending_invites
    load_admin_data
    @@invites_cache.select { |i| !i['used'] }
  end

  # Revoke invite
  def self.revoke_invite(token)
    load_admin_data
    invite = @@invites_cache.find { |i| i['token'] == token }
    return false unless invite

    @@invites_cache.delete(invite)
    save_admin_data
    true
  end

  # Deactivate admin
  def deactivate
    load_admin_data
    admin_data = @@admins_cache.find { |a| a['id'] == self.id }
    return false unless admin_data

    admin_data['active'] = false
    self.active = false
    self.class.save_admin_data
    true
  end
end
