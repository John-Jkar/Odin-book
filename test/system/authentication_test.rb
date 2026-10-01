require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "a visitor can sign up and is taken to the feed" do
    visit root_path
    assert_text "Log in"

    visit new_user_registration_path
    fill_in "Username", with: "dave"
    fill_in "Email", with: "dave@example.com"
    fill_in "Password", with: DEFAULT_PASSWORD
    fill_in "Password confirmation", with: DEFAULT_PASSWORD
    click_button "Sign up"

    assert_selector ".navbar"
    assert_text "dave"
    assert_selector ".page-title", text: "Feed"

    # The fresh account sees an empty feed rather than other people's posts.
    assert_text "Your feed is empty"
  end

  test "a user can sign in and sign out" do
    sign_in_as "alice"

    assert_selector ".nav-username", text: "alice"
    assert_text "Just finished the Odinbook models layer."

    sign_out
    assert_text "Log in"
    assert_no_selector ".navbar"
  end

  test "signing in with a bad password shows an error" do
    visit new_user_session_path
    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "not-the-password"
    click_button "Log in"

    assert_selector ".flash-alert"
    assert_no_selector ".navbar"
  end

  test "signed out visitors are redirected to sign in" do
    visit posts_path
    assert_selector "h1", text: "Log in"
  end
end
