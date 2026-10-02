require "test_helper"

class PostsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "the feed loads and shows own and followed users' posts" do
    get posts_path

    assert_response :success
    assert_select "h1", "Feed"
    assert_select ".post", minimum: 2

    assert_select ".post", text: /Just finished the Odinbook models layer/
    assert_select ".post", text: /Selling cars, still cheaper than therapy/
  end

  test "the feed excludes posts from users who are not followed" do
    get posts_path

    assert_select ".post", text: /New cat, same amount of chaos/, count: 0
  end

  test "a post shows its author, content, comments and like count" do
    get posts_path

    assert_select ".post", minimum: 1 do
      assert_select ".post-author", text: "alice"
      assert_select ".post-content", text: /Just finished the Odinbook models layer/
      assert_select ".comment-content", text: /Models look clean, keep going/
      assert_select ".like-count", text: "2 likes"
      assert_select ".comment-count-link", text: "1 comment"
    end
  end

  test "a user can create a post" do
    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { content: "Hello from the test suite." } }
    end

    assert_redirected_to posts_path
    follow_redirect!
    assert_select ".post-content", text: /Hello from the test suite/
  end

  test "creating a post with blank content fails validation" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { content: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors", text: /Content can.t be blank/
  end

  test "the author can delete their own post" do
    assert_difference "Post.count", -1 do
      delete post_path(posts(:alice_post))
    end

    assert_redirected_to posts_path
  end

  test "a user cannot delete someone else's post" do
    assert_no_difference "Post.count" do
      delete post_path(posts(:bob_post))
    end

    assert_response :not_found
  end

  test "the delete button only appears on your own posts" do
    get posts_path

    assert_select "form[action=?]", post_path(posts(:alice_post))
    assert_select "form[action=?]", post_path(posts(:bob_post)), count: 0
  end

  test "the For You page shows posts from everyone except the current user" do
    get discover_path

    assert_response :success
    assert_select "h1", "For You"

    # bob and carol's posts are both present
    assert_select ".post", text: /Selling cars, still cheaper than therapy/, minimum: 1
    assert_select ".post", text: /New cat, same amount of chaos/, minimum: 1

    # alice's own post is not
    assert_select ".post", text: /Just finished the Odinbook models layer/, count: 0
  end

  test "the For You page excludes the current user's own posts" do
    get discover_path

    assert_select ".post", text: /Just finished the Odinbook models layer/, count: 0
  end

  test "the For You page shows followed and unfollowed users alike" do
    get discover_path

    # alice follows bob, and does not follow carol
    assert_select ".post", text: /Selling cars, still cheaper than therapy/, minimum: 1
    assert_select ".post", text: /New cat, same amount of chaos/, minimum: 1
  end

  test "the For You page orders posts newest first" do
    get discover_path

    timestamps = css_select(".post .post-timestamp").map { |n| n.text.strip }
    assert_operator timestamps.length, :>=, 2
  end

  test "the For You page requires sign in" do
    delete destroy_user_session_path
    get discover_path

    assert_redirected_to new_user_session_path
  end

  test "the For You page links back to the people directory" do
    get discover_path
    assert_select "a[href=?]", users_path
  end

  test "a user can create a post with a picture" do
    assert_difference "Post.count", 1 do
      post posts_path, params: {
        post: { content: "With a picture.", image: uploaded_image }
      }
    end

    assert_redirected_to posts_path
    assert Post.recent.first.image.attached?
  end

  test "a post with only a picture and no text is allowed" do
    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { content: "", image: uploaded_image } }
    end

    assert_redirected_to posts_path
  end

  test "an attached picture renders on the feed" do
    post = Post.create!(user: users(:alice), content: "Picture post.")
    post.image.attach(
      io: file_fixture("sample.png").open,
      filename: "sample.png",
      content_type: "image/png"
    )

    get posts_path

    assert_select ".post-image"
  end

  test "a post with neither text nor a picture is rejected" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { content: "" } }
    end

    assert_response :unprocessable_entity
  end

  private

  def uploaded_image
    Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample.png"),
      "image/png"
    )
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
