class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :content, presence: true, length: { maximum: 280 }

  scope :chronological, -> { order(created_at: :asc) }
end
