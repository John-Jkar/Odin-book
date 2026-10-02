require "application_system_test_case"

class SocialFlowTest < ApplicationSystemTestCase
  test "a user can publish a post that appears in the feed" do
    sign_in_as "alice"

    fill_in "What's on your mind?", with: "Shipping the new design system."
    click_button "Post"

    assert_text "Shipping the new design system."
    assert_selector ".flash-notice"
  end

  test "a user can publish a post with a picture" do
    sign_in_as "alice"

    fill_in "What's on your mind?", with: "A picture from the system test."
    attach_file "Add a picture", Rails.root.join("test/fixtures/files/sample.png")
    click_button "Post"

    assert_text "A picture from the system test."
    assert_selector ".post-image", wait: 10
  end

  test "the feed shows own and followed posts but not strangers" do
    sign_in_as "alice"

    # alice follows bob (accepted), so both posts belong in her feed.
    assert_text "Just finished the Odinbook models layer."
    assert_text "Selling cars, still cheaper than therapy."

    # carol has not been accepted by alice.
    assert_no_text "New cat, same amount of chaos as usual."
  end

  test "For You shows other people's posts and hides your own" do
    sign_in_as "alice"

    click_link "For You"

    assert_selector "h1", text: "For You"
    assert_text "Selling cars, still cheaper than therapy."
    assert_text "New cat, same amount of chaos as usual."

    # Your own post is excluded from For You.
    assert_no_selector "#post-#{posts(:alice_post).id}"
  end

  test "a like can be added and removed from the discovery feed" do
    sign_in_as "bob"
    visit discover_path

    post_selector = "#post-#{posts(:alice_post).id}"

    # bob already likes alice's post (fixture), which has 2 likes.
    within post_selector do
      assert_text "2 likes"
      click_button "♥ Liked"
    end

    # Reacquire the post after the DOM update and verify the like was removed.
    within post_selector do
      assert_text "1 like"
      click_button "♡ Like"
    end

    # Final verification after the second DOM update.
    within post_selector do
      assert_text "2 likes"
    end
  end

  test "a comment can be posted on the discovery feed" do
    sign_in_as "bob"
    visit discover_path

    # The comment submit redirects, replacing the post; assertions after the
    # block stay outside it deliberately.
    within find("#post-#{posts(:carol_post).id}") do
      fill_in "Add a comment", with: "Great cat story!"
      click_button "Comment"
    end

    assert_text "Great cat story!"
    assert_text "1 comment"
  end

  test "a follow request can be sent, cancelled and accepted" do
    sign_in_as "alice"
    visit users_path

    # Accepting redirects and re-renders the list, so reacquire the row
    # instead of asserting inside the pre-redirect scope.
    within find(".user-row", text: "carol") do
      assert_button "Accept"
      click_button "Accept"
    end

    within find(".user-row", text: "carol") do
      assert_button "Follow"
    end

    within find(".user-row", text: "bob") do
      assert_button "Following"
    end
  end

  test "a pending follow request can be declined" do
    sign_in_as "alice"
    visit users_path

    assert_text "Wants to follow you"

    within find(".user-row", text: "carol") do
      click_button "Decline"
    end

    within find(".user-row", text: "carol") do
      assert_button "Follow"
    end

    assert_no_text "Wants to follow you"
  end

  test "a user can edit their profile" do
    sign_in_as "alice"

    find(".nav-username").click
    assert_selector "h1", text: "alice"
    click_link "Edit profile"

    fill_in "Full name", with: "Alice A. Anderson"
    fill_in "Location", with: "Portland, Oregon"
    click_button "Save changes"

    assert_selector ".flash-notice"
    assert_text "Alice A. Anderson"
    assert_text "Portland, Oregon"
  end
end
