require "test_helper"

class LikesAndCommentsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "a user can like a post" do
    post = posts(:carol_post)
    assert_not post.reload.liked_by?(users(:alice))

    post post_like_path(post)

    assert_redirected_to posts_path
    assert post.reload.liked_by?(users(:alice))
    assert_equal 1, post.reload.likes_count
  end

  test "a user can unlike a post" do
    post = posts(:alice_post)

    delete post_like_path(post)

    assert_redirected_to posts_path
    assert_not post.reload.liked_by?(users(:alice))
  end

  test "liking twice does not create a duplicate like" do
    post = posts(:carol_post)

    assert_difference "Like.count", 1 do
      post post_like_path(post)
    end

    assert_no_difference "Like.count" do
      post post_like_path(post)
    end
  end

  test "the like button reflects the current user's like" do
    get posts_path

    # alice already likes bob's post, so the button un-likes it
    assert_select "form[action=?] input[name=?][value=?]",
      post_like_path(posts(:bob_post)), "_method", "delete"

    # alice has not liked her own post, so the button likes it
    assert_select "form[action=?] input[name=?]", post_like_path(posts(:alice_post)),
      "_method", count: 0
  end

  test "a user can comment on a post" do
    post = posts(:bob_post)

    assert_difference "Comment.count", 1 do
      post post_comments_path(post), params: { comment: { content: "Great post!" } }
    end

    assert_redirected_to posts_path
    follow_redirect!
    assert_select ".comment-content", text: /Great post!/
  end

  test "commenting from the discovery feed returns to the discovery feed" do
    post = posts(:carol_post)

    assert_difference "Comment.count", 1 do
      post post_comments_path(post),
        params: { comment: { content: "Found you here!" } },
        headers: { "HTTP_REFERER" => discover_url }
    end

    assert_redirected_to discover_path
    follow_redirect!
    assert_select ".comment-content", text: /Found you here!/
  end

  test "a blank comment is rejected" do
    post = posts(:bob_post)

    assert_no_difference "Comment.count" do
      post post_comments_path(post), params: { comment: { content: "" } }
    end

    assert_redirected_to posts_path
    follow_redirect!
    assert_select ".flash-alert"
  end

  test "a user can delete their own comment" do
    comment = comments(:alice_on_bob)

    assert_difference "Comment.count", -1 do
      delete comment_path(comment)
    end
  end

  test "a user cannot delete someone else's comment" do
    assert_no_difference "Comment.count" do
      delete comment_path(comments(:bob_on_alice))
    end

    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
