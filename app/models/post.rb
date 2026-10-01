class Post < ApplicationRecord
  belongs_to :user

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  validates :content, presence: true, length: { maximum: 280 }

  scope :recent, -> { order(created_at: :desc) }

  # Newsfeed: the user's own posts plus those of everyone they follow.
  scope :from_feed_of, ->(user) {
    where(user_id: [ user.id, *user.following_ids ]).recent
  }

  # "For You": everyone's posts except the current user's own, so the page is
  # purely discovery.
  scope :from_discover_for, ->(user) {
    where.not(user_id: user&.id).recent
  }

  def liked_by?(other)
    return false if other.nil?

    likes.exists?(user_id: other.id)
  end

  def like_count
    likes_count
  end
end
