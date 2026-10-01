require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "user has posts" do
    assert_not_empty users(:alice).posts
    assert_equal [ posts(:alice_post) ], users(:alice).posts.to_a
  end

  test "user has comments" do
    assert_includes users(:bob).comments, comments(:bob_on_alice)
  end

  test "user has likes" do
    assert_includes users(:carol).likes, likes(:carol_likes_alice_post)
    assert_equal 1, users(:carol).likes.count
  end

  test "user has an attached avatar" do
    assert_respond_to users(:alice), :avatar
  end

  test "following and followers reflect only accepted relationships" do
    assert_includes users(:alice).following, users(:bob)
    assert_includes users(:bob).following, users(:alice)

    # carol_requested_alice is pending, so no follow should exist yet
    assert_not_includes users(:alice).following, users(:carol)
    assert_not_includes users(:carol).following, users(:alice)
  end

  test "follow_requests_sent includes pending requests" do
    assert_includes users(:carol).follow_requests_sent, relationships(:carol_requests_alice)
    assert users(:carol).requested?(users(:alice))
  end

  test "follow_requests_received tracks incoming requests" do
    assert users(:alice).requested_by?(users(:carol))
    assert_equal 1, users(:alice).follow_requests_received.pending.count
  end

  test "following? is true only for accepted follows" do
    assert users(:alice).following?(users(:bob))
    assert_not users(:alice).following?(users(:carol))
  end

  test "followable? excludes self" do
    assert_not users(:alice).followable?(users(:alice))
    assert users(:alice).followable?(users(:bob))
  end

  test "destroying a user destroys their dependent records" do
    user = users(:carol)
    user.destroy!

    assert_equal 0, Post.where(user_id: user.id).count
    assert_equal 0, Like.where(user_id: user.id).count
    assert_equal 0, Relationship.where(follower_id: user.id).count
  end

  test "username must be present and unique" do
    duplicate = User.new(email: "new@example.com", password: "password123",
      username: "alice")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
  end

  test "username is case insensitively unique" do
    duplicate = User.new(email: "new@example.com", password: "password123",
      username: "ALICE")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "has already been taken"
  end

  test "username is restricted to letters numbers and underscores" do
    user = User.new(email: "new@example.com", password: "password123",
      username: "not valid!")

    assert_not user.valid?
    assert_includes user.errors[:username].join, "letters, numbers and underscores"
  end

  test "username length is bounded" do
    user = User.new(email: "new@example.com", password: "password123", username: "ab")

    assert_not user.valid?
    assert_predicate user.errors[:username], :any?
  end

  test "username is stripped of surrounding whitespace" do
    user = User.create!(email: "spaced@example.com", password: "password123",
      username: "  spaced  ")

    assert_equal "spaced", user.username
  end

test "website must be an absolute http(s) URL" do
  user = User.new(email: "web@example.com", password: "password123",
    username: "webby", website: "javascript:alert(1)")

  assert_not user.valid?
  assert_includes user.errors[:website].join, "must start with http:// or https://"
  end

  test "website accepts a blank value and an https URL" do
    blank = User.new(email: "a@example.com", password: "password123", username: "blankish")
    assert blank.valid?

    good = User.new(email: "b@example.com", password: "password123",
      username: "webster", website: "https://example.com")
    assert good.valid?
  end

  test "a new user is sent a welcome email" do
    assert_difference "User.count", 1 do
      User.create!(email: "welcomed@example.com", password: "password123",
        username: "welcomed")
    end

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob)
  end
end
