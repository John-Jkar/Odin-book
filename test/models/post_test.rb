require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "post belongs to a user" do
    assert_equal users(:alice), posts(:alice_post).user
    assert_equal posts(:alice_post), users(:alice).posts.first
  end

  test "post has comments" do
    assert_equal [ comments(:bob_on_alice) ], posts(:alice_post).comments.to_a
  end

  test "post has likes" do
    assert_equal 2, posts(:alice_post).likes.count
  end

  test "counter caches track comments and likes" do
    # Fixtures bypass the counter cache, so start from a fresh post.
    post = Post.create!(user: users(:alice), content: "Counted post.")

    assert_equal 0, post.reload.likes_count
    assert_equal 0, post.comments_count

    post.likes.create!(user: users(:alice))
    post.comments.create!(user: users(:alice), content: "Mine too.")

    assert_equal 1, post.reload.likes_count
    assert_equal 1, post.comments_count

    post.likes.first.destroy!
    post.comments.first.destroy!

    assert_equal 0, post.reload.likes_count
    assert_equal 0, post.comments_count
  end

  test "liked_by? reports whether the user liked the post" do
    post = posts(:alice_post)

    assert post.liked_by?(users(:bob))
    assert_not post.liked_by?(users(:alice))
  end

  test "content must be present" do
    post = Post.new(user: users(:alice), content: "")

    assert_not post.valid?
    assert_includes post.errors[:content], "can't be blank"
  end

  test "content length is capped" do
    post = Post.new(user: users(:alice), content: "a" * 281)

    assert_not post.valid?
  end

  test "post must belong to a user" do
    post = Post.new(content: "Orphan post")

    assert_not post.valid?
  end

  test "from_feed_of returns own and followed users' posts, newest first" do
    alice = users(:alice)

    # alice follows bob, so bob_post belongs in alice's feed alongside alice_post.
    feed = Post.from_feed_of(alice)

    assert_includes feed, posts(:alice_post)
    assert_includes feed, posts(:bob_post)

    # carol's post must not appear
    assert_not_includes feed, posts(:carol_post)

    timestamps = feed.to_a.map(&:created_at)
    assert_equal timestamps.sort.reverse, timestamps
  end

  test "from_feed_of still returns own posts when following nobody" do
    carol = users(:carol)
    Relationship.delete_all

    feed = Post.from_feed_of(carol)

    assert_equal [ posts(:carol_post) ], feed.to_a
  end

  test "from_discover_for returns everyone else's posts and not your own" do
    alice = users(:alice)
    posts = Post.from_discover_for(alice).to_a

    assert_not_includes posts, posts(:alice_post)
    assert_includes posts, posts(:bob_post)
    assert_includes posts, posts(:carol_post)
  end

  test "from_discover_for includes users you do not follow" do
    alice = users(:alice)

    # alice follows bob only
    assert alice.following?(users(:bob))
    assert_not alice.following?(users(:carol))

    assert_includes Post.from_discover_for(alice).to_a, posts(:carol_post)
  end

  test "from_discover_for orders newest first" do
    posts = Post.from_discover_for(users(:alice)).to_a

    assert_operator posts.length, :>=, 2
    timestamps = posts.map(&:created_at)
    assert_equal timestamps.sort.reverse, timestamps
  end

  test "from_discover_for tolerates a nil user" do
    assert_nothing_raised do
      Post.from_discover_for(nil).to_a
    end
  end

  test "destroying a post destroys its comments and likes" do
    post = posts(:alice_post)
    post_id = post.id

    assert_difference "Comment.count", -1 do
      assert_difference "Like.count", -post.likes.count do
        post.destroy!
      end
    end

    assert_equal 0, Comment.where(post_id: post_id).count
    assert_equal 0, Like.where(post_id: post_id).count
  end
end
