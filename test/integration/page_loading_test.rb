require "test_helper"

# The assignment asks for "a basic set of integration tests which let you know
# if each page is loading properly". This walks every page a signed-in user
# can reach and asserts a successful render.
class PageLoadingTest < ActionDispatch::IntegrationTest
  setup do
    post user_session_path, params: {
      user: { email: users(:alice).email, password: "password" }
    }
  end

  test "every signed in page loads" do
    pages = {
      "feed" => posts_path,
      "for you" => discover_path,
      "find people" => users_path,
      "own profile" => user_path(users(:alice)),
      "another profile" => user_path(users(:bob)),
      "edit profile" => edit_profile_path,
      "devise account settings" => edit_user_registration_path
    }

    pages.each do |label, path|
      get path

      assert_response :success, "#{label} (#{path}) did not load successfully"
    end
  end

  test "the root path sends signed in users to the feed" do
    get root_path

    assert_redirected_to posts_path
  end

  test "the landing page loads for signed out visitors" do
    delete destroy_user_session_path

    get root_path

    assert_response :success
    assert_select ".landing-title"
    assert_select "a", text: "Log in"
    assert_select "a", text: "Sign up"
  end

  test "the password reset page loads" do
    # Devise sends signed in users away from the password form.
    get new_user_password_path
    assert_redirected_to posts_path

    delete destroy_user_session_path

    get new_user_password_path
    assert_response :success

    # Reaching the edit form without a reset token requires signing in first.
    get edit_user_password_path
    assert_redirected_to new_user_session_path
  end

  test "sign out pages load when signed out" do
    delete destroy_user_session_path

    get new_user_session_path
    assert_response :success

    get new_user_registration_path
    assert_response :success

    get new_user_password_path
    assert_response :success
  end

  test "unknown ids return not found rather than a server error" do
    get user_path(id: 0)
    assert_response :not_found

    get post_path(id: 0)
    assert_response :not_found
  end
end
