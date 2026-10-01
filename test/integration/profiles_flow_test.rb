require "test_helper"

class ProfilesFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "a profile page shows profile info, photo slot and posts" do
    get user_path(users(:alice))

    assert_response :success
    assert_select "h1", "alice"
    assert_select ".profile-details", text: /Alice Anderson/
    assert_select ".profile-details", text: /Portland, OR/
    assert_select ".profile-details", text: /Backend developer, tea drinker/
    assert_select ".avatar"
    assert_select ".profile-stats", text: /1 post/
    assert_select ".post", text: /Just finished the Odinbook models layer/
  end

  test "another user's profile page loads and offers a follow button" do
    get user_path(users(:bob))

    assert_response :success
    assert_select "h1", "bob"
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_path(users(:bob)), "_method", "delete"
  end

  test "a profile with no posts shows an empty state" do
    quiet = User.create!(email: "quiet@example.com", password: "password123",
      username: "quiet")

    get user_path(quiet)

    assert_response :success
    assert_select ".empty-state"
  end

  test "the profile edit form loads with prefilled values" do
    get edit_profile_path

    assert_response :success
    assert_select "h1", "Edit Profile"
    assert_select "input[name=?][value=?]", "user[username]", "alice"
    assert_select "input[type=?][name=?]", "file", "user[avatar]"
  end

  test "a user can update their profile" do
    patch profile_path, params: {
      user: {
        username: "alice_updated",
        full_name: "Alice A.",
        location: "Seattle, WA",
        bio: "Now writing tests."
      }
    }

    assert_redirected_to user_path(users(:alice))
    follow_redirect!
    assert_select "h1", "alice_updated"
    assert_select ".profile-details", text: /Seattle, WA/
  end

  test "a rejected profile update redisplays the form with errors" do
    patch profile_path, params: { user: { username: "no" } }

    assert_response :unprocessable_entity
    assert_select ".errors", text: /Username is too short/
  end

  test "a username collision is rejected" do
    patch profile_path, params: { user: { username: "bob" } }

    assert_response :unprocessable_entity
    assert_select ".errors", text: /Username has already been taken/
  end

  test "the profile page links to the editor for your own profile only" do
    get user_path(users(:alice))
    assert_select "a[href=?]", edit_profile_path

    get user_path(users(:bob))
    assert_select "a[href=?]", edit_profile_path, count: 0
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
