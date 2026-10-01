require "test_helper"

class LikeTest < ActiveSupport::TestCase
  test "like belongs to a user and a post" do
    like = likes(:carol_likes_alice_post)

    assert_equal users(:carol), like.user
    assert_equal posts(:alice_post), like.post
    assert_includes posts(:alice_post).likes, like
    assert_includes users(:carol).likes, like
  end

  test "a user cannot like the same post twice" do
    duplicate = Like.new(user: users(:carol), post: posts(:alice_post))

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:user_id], :any?
  end

  test "likes are unique per user and post in the database" do
    assert_raises ActiveRecord::RecordNotUnique do
      Like.connection.execute(
        "INSERT INTO likes (user_id, post_id, created_at, updated_at) " \
        "VALUES (#{users(:carol).id}, #{posts(:alice_post).id}, now(), now())"
      )
    end
  end

  test "like requires a user and a post" do
    assert_not Like.new.valid?
  end

  test "destroying a like decrements the post counter" do
    post = posts(:alice_post)

    assert_difference "post.reload.likes_count", -1 do
      likes(:carol_likes_alice_post).destroy!
    end
  end
end
