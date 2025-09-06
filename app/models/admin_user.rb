class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email", "id", "updated_at", "reset_password_sent_at", "remember_created_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
