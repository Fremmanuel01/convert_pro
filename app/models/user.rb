class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth)
    # Check if a user already exists with this email address from standard sign-up
    user = User.find_by(email: auth.info.email)

    if user
      # Link the Google provider to the existing account
      user.update(provider: auth.provider, uid: auth.uid)
      user.skip_confirmation! unless user.confirmed?
      user.save if user.changed?
      user
    else
      # Create a brand new user — auto-confirm Google OAuth users
      where(provider: auth.provider, uid: auth.uid).first_or_create do |new_user|
        new_user.email    = auth.info.email
        new_user.password = Devise.friendly_token[0, 20]
        new_user.skip_confirmation!
      end
    end
  end

  enum :plan, { free: 0, pro: 1 }, default: :free
  enum :subscription_status, { inactive: 0, active: 1, incomplete: 2, cancelled: 3, expired: 4 }, default: :inactive

  validates :conversions_count, numericality: { greater_than_or_equal_to: 0 }
  
  has_many :conversions, dependent: :destroy
  has_many :analytics_events, dependent: :nullify

  after_create_commit :track_signup

  def conversion_limit_per_day
    pro? && active? ? Float::INFINITY : 5
  end

  private

  def track_signup
    Analytics.track(:signup_completed, user: self, properties: { source: provider.presence || "email" })
  end
end
