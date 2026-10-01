class User < ApplicationRecord
  has_one_attached :avatar

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  has_many :follow_requests_sent, class_name: "Relationship",
    foreign_key: :follower_id, inverse_of: :follower, dependent: :destroy
  has_many :follow_requests_received, class_name: "Relationship",
    foreign_key: :following_id, inverse_of: :following, dependent: :destroy

  # Only accepted requests count as an actual follow, so scope the join.
  has_many :following_relationships, -> { accepted }, class_name: "Relationship",
    foreign_key: :follower_id, inverse_of: :follower
  has_many :follower_relationships, -> { accepted }, class_name: "Relationship",
    foreign_key: :following_id, inverse_of: :following

  has_many :following, through: :following_relationships, source: :following
  has_many :followers, through: :follower_relationships, source: :follower

  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :validatable

  validates :username, presence: true, uniqueness: { case_sensitive: false },
    length: { in: 3..30 }, format: { with: /\A[a-zA-Z0-9_]+\z/,
      message: "can only contain letters, numbers and underscores" }
  # Rendered as a link href, so only allow absolute http(s) URLs.
  validates :website, format: { with: /\Ahttps?:\/\/\S+\z/,
    message: "must start with http:// or https://" }, allow_blank: true

  before_validation :normalize_username

  after_create_commit :send_welcome_email

  def following?(other)
    return false if other.nil? || other.id.nil?

    following.exists?(other.id)
  end

  def requested?(other)
    return false if other.nil? || other.id.nil?

    follow_requests_sent.exists?(following_id: other.id)
  end

  def requested_by?(other)
    return false if other.nil? || other.id.nil?

    follow_requests_received.exists?(follower_id: other.id)
  end

  def followable?(other)
    other.present? && other != self
  end

  def profile_feed_posts
    Post.includes(:user, :comments, :likes).where(user_id: id).recent
  end

  private

  def normalize_username
    self.username = username.strip if username.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
