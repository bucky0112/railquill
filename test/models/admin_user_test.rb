require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  # Setup for tests
  def setup
    @admin_user = admin_users(:one)
  end

  # Validation tests (inherited from Devise)
  test "should require email" do
    admin_user = AdminUser.new(password: "password", password_confirmation: "password")
    assert_not admin_user.valid?
    assert_includes admin_user.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    admin_user = AdminUser.new(email: "invalid-email", password: "password", password_confirmation: "password")
    assert_not admin_user.valid?
    assert_includes admin_user.errors[:email], "is invalid"
  end

  test "should require unique email" do
    existing_admin = AdminUser.create!(email: "unique@example.com", password: "password")
    duplicate_admin = AdminUser.new(email: "unique@example.com", password: "password")
    assert_not duplicate_admin.valid?
    assert_includes duplicate_admin.errors[:email], "has already been taken"
  end

  test "should require password" do
    admin_user = AdminUser.new(email: "test@example.com")
    assert_not admin_user.valid?
    assert_includes admin_user.errors[:password], "can't be blank"
  end

  test "should require minimum password length" do
    admin_user = AdminUser.new(email: "test@example.com", password: "short")
    assert_not admin_user.valid?
    assert_includes admin_user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "should accept valid admin user" do
    admin_user = AdminUser.new(email: "valid@example.com", password: "password123")
    assert admin_user.valid?
  end

  # Devise functionality tests
  test "should encrypt password" do
    admin_user = AdminUser.create!(email: "test@example.com", password: "plaintext")
    assert_not_nil admin_user.encrypted_password
    assert_not_equal "plaintext", admin_user.encrypted_password
  end

  test "should authenticate with valid password" do
    admin_user = AdminUser.create!(email: "test@example.com", password: "correctpassword")
    assert admin_user.valid_password?("correctpassword")
  end

  test "should not authenticate with invalid password" do
    admin_user = AdminUser.create!(email: "test@example.com", password: "correctpassword")
    assert_not admin_user.valid_password?("wrongpassword")
  end

  test "should be rememberable" do
    admin_user = AdminUser.create!(email: "test@example.com", password: "password")
    admin_user.remember_me!
    assert_not_nil admin_user.remember_created_at
  end

  test "should be recoverable" do
    admin_user = AdminUser.create!(email: "test@example.com", password: "password")
    # Test that the model has recoverable functionality without actually sending email
    assert admin_user.respond_to?(:send_reset_password_instructions)
    assert admin_user.respond_to?(:reset_password_token)
    assert admin_user.respond_to?(:reset_password_sent_at)
  end

  # Edge cases
  test "should handle case insensitive email" do
    AdminUser.create!(email: "Test@Example.com", password: "password")
    duplicate_admin = AdminUser.new(email: "test@example.com", password: "password")
    assert_not duplicate_admin.valid?
    assert_includes duplicate_admin.errors[:email], "has already been taken"
  end

  test "should strip whitespace from email" do
    admin_user = AdminUser.create!(email: "  test@example.com  ", password: "password")
    assert_equal "test@example.com", admin_user.email
  end

  # Ransack configuration tests
  test "should define ransackable attributes" do
    expected_attributes = [ "created_at", "email", "id", "updated_at", "reset_password_sent_at", "remember_created_at" ]
    assert_equal expected_attributes, AdminUser.ransackable_attributes
  end

  test "should define empty ransackable associations" do
    assert_equal [], AdminUser.ransackable_associations
  end

  # Security tests
  test "should not expose sensitive attributes in ransackable" do
    ransackable_attrs = AdminUser.ransackable_attributes
    assert_not_includes ransackable_attrs, "encrypted_password"
    assert_not_includes ransackable_attrs, "reset_password_token"
  end

  # Database constraints
  test "should handle reasonably long emails" do
    long_email = "#{'a' * 50}@example.com"
    admin_user = AdminUser.new(email: long_email, password: "password")
    assert admin_user.valid?
  end
end
