require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "visitors are redirected to sign in from every protected page" do
    [ posts_path, users_path, user_path(users(:alice)), edit_profile_path ].each do |path|
      get path
      assert_redirected_to new_user_session_path, "#{path} should require sign in"
    end
  end

  test "the sign in page is reachable when signed out" do
    get new_user_session_path

    assert_response :success
    assert_select "form[action=?]", user_session_path
  end

  test "the sign up page is reachable when signed out" do
    get new_user_registration_path

    assert_response :success
    assert_select "input[name=?]", "user[username]"
  end

  test "a user can sign in with a valid password" do
    post user_session_path, params: {
      user: { email: users(:alice).email, password: "password" }
    }

    assert_redirected_to posts_path
    follow_redirect!
    assert_select "h1", "Feed"
  end

  test "sign in fails with the wrong password" do
    post user_session_path, params: {
      user: { email: users(:alice).email, password: "wrong" }
    }

    assert_response :unprocessable_entity
    assert_select ".flash-alert"
  end

  test "a visitor can register and lands on the feed" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          username: "newcomer",
          email: "newcomer@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.find_by(username: "newcomer")
    assert_redirected_to posts_path
    assert user.present?

    follow_redirect!
    assert_select "h1", "Feed"
  end

  test "registration rejects a username that is already taken" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "alice",
          email: "another@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "registration rejects a short password" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          username: "shorty",
          email: "shorty@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "a user can sign out" do
    sign_in users(:alice)

    delete destroy_user_session_path

    assert_redirected_to root_path
    get posts_path
    assert_redirected_to new_user_session_path
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
