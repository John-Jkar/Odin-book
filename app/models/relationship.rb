class Relationship < ApplicationRecord
  PENDING = "pending"
  ACCEPTED = "accepted"

  belongs_to :follower, class_name: "User", inverse_of: :follow_requests_sent
  belongs_to :following, class_name: "User", inverse_of: :follow_requests_received

  validates :status, inclusion: { in: [ PENDING, ACCEPTED ] }
  validates :follower_id, uniqueness: { scope: :following_id }
  validate :cannot_follow_self

  scope :accepted, -> { where(status: ACCEPTED) }
  scope :pending, -> { where(status: PENDING) }

  def pending?
    status == PENDING
  end

  def accepted?
    status == ACCEPTED
  end

  def accept!
    update!(status: ACCEPTED)
  end

  private

  def cannot_follow_self
    if follower_id.present? && follower_id == following_id
      errors.add(:following_id, "can't be yourself")
    end
  end
end
