require "test_helper"

class FollowingFlowTest < ActionDispatch::IntegrationTest
  test "the users index lists other users but not yourself" do
    sign_in_as users(:alice)
    get users_path

    assert_response :success
    assert_select "h1", "Find People"
    assert_select ".user-row", count: 2
    assert_select ".user-row", text: /bob/
    assert_select ".user-row", text: /carol/
    assert_select ".user-row", text: /alice/, count: 0
  end

  test "a user can send a follow request" do
    alice = users(:alice)
    bob = users(:bob)
    Relationship.delete_all

    sign_in_as alice
    assert_difference "Relationship.count", 1 do
      post user_follow_path(bob)
    end

    assert_redirected_to users_path
    assert alice.reload.requested?(bob)
    assert_not alice.following?(bob)
    assert_equal Relationship::PENDING, Relationship.last.status
  end

  test "a user cannot request the same follow twice" do
    alice = users(:alice)
    carol = users(:carol)

    sign_in_as alice
    # carol already has a pending request to alice; alice requesting carol is a
    # distinct row and is allowed.
    assert_difference "Relationship.count", 1 do
      post user_follow_path(carol)
    end

    assert_no_difference "Relationship.count" do
      post user_follow_path(carol)
    end
  end

  test "a user cannot follow themselves" do
    alice = users(:alice)
    sign_in_as alice

    assert_no_difference "Relationship.count" do
      post user_follow_path(alice)
    end

    assert_response :redirect
  end

  test "a user can cancel a pending follow request" do
    alice = users(:alice)
    carol = users(:carol)
    pending = Relationship.create!(follower: alice, following: carol)

    sign_in_as alice
    assert_difference "Relationship.count", -1 do
      delete user_follow_path(carol)
    end

    assert_not Relationship.exists?(pending.id)
    assert_not alice.reload.requested?(carol)
  end

  test "a user can unfollow someone" do
    alice = users(:alice)
    bob = users(:bob)

    sign_in_as alice
    assert_difference "Relationship.count", -1 do
      delete user_follow_path(bob)
    end

    assert_not alice.reload.following?(bob)
  end

  test "the recipient can accept a follow request" do
    carol = users(:carol)
    alice = users(:alice)
    request = relationships(:carol_requests_alice)

    sign_in_as alice
    patch user_follow_request_path(alice, request)

    assert_redirected_to users_path
    assert request.reload.accepted?
    assert carol.reload.following?(alice)
  end

  test "the recipient can decline a follow request" do
    request = relationships(:carol_requests_alice)

    sign_in_as users(:alice)
    assert_difference "Relationship.count", -1 do
      delete user_follow_request_path(users(:alice), request)
    end

    assert_not users(:carol).reload.requested?(users(:alice))
  end

  test "a user cannot act on a follow request they did not receive" do
    request = relationships(:carol_requests_alice)

    sign_in_as users(:bob)
    assert_no_difference "Relationship.count" do
      patch user_follow_request_path(users(:alice), request)
    end

    assert_response :not_found
  end

  test "the users index offers the right button for each relationship" do
    alice = users(:alice)
    carol = users(:carol)

    sign_in_as alice
    get users_path

    # alice follows bob, so she is offered an unfollow
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_path(users(:bob)), "_method", "delete"

    # carol requested alice, so alice is offered accept/decline
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_request_path(carol, relationships(:carol_requests_alice)),
      "_method", "patch"
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_request_path(carol, relationships(:carol_requests_alice)),
      "_method", "delete"
  end

  test "accepting a request adds the new follower to the profile" do
    alice = users(:alice)
    carol = users(:carol)

    sign_in_as alice
    assert_equal 1, alice.followers.count

    patch user_follow_request_path(alice, relationships(:carol_requests_alice))

    assert_equal 2, alice.reload.followers.count
    assert carol.following?(alice)

    get user_path(alice)
    assert_response :success
    assert_select ".profile-stats", text: /2 followers/
  end

  # Regression: `following?` used to be checked before `incoming_request`, so a
  # recipient who already followed the sender saw "Following" instead of
  # "Accept" and the pending request was invisible.
  test "a recipient who already follows the sender can still see and accept the request" do
    alice = users(:alice)
    bob = users(:bob)
    Relationship.delete_all

    # bob already follows alice
    Relationship.create!(follower: bob, following: alice, status: Relationship::ACCEPTED)
    assert bob.reload.following?(alice)

    # alice now requests bob back
    sign_in_as alice
    post user_follow_path(bob)
    assert alice.reload.requested?(bob)

    # bob sees the request on the users index...
    sign_out
    sign_in_as bob
    get users_path
    request = bob.follow_requests_received.pending.find_by(follower_id: alice.id)
    assert request, "expected a pending request from alice to bob"
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_request_path(alice, request), "_method", "patch"

    # ...and on alice's profile page
    get user_path(alice)
    assert_select "form[action=?] input[name=?][value=?]",
      user_follow_request_path(alice, request), "_method", "patch"

    # and accepting it works
    patch user_follow_request_path(alice, request)
    assert request.reload.accepted?
    assert alice.reload.following?(bob)
  end

  test "the nav shows a badge with the number of pending requests" do
    sign_in_as users(:alice)
    get posts_path
    assert_select ".badge-alert", text: "1"

    get user_path(users(:alice))
    assert_select ".badge-alert", text: "1"
  end

  test "the nav badge disappears once requests are resolved" do
    alice = users(:alice)
    request = relationships(:carol_requests_alice)

    sign_in_as alice
    patch user_follow_request_path(alice, request)

    get posts_path
    assert_select ".badge-alert", count: 0
  end

  test "no badge is shown when there are no pending requests" do
    Relationship.delete_all
    sign_in_as users(:alice)

    get posts_path
    assert_select ".badge-alert", count: 0
  end

  private

  # Devise keeps the existing session when you sign in while already
  # authenticated, so switch accounts explicitly.
  def sign_out
    delete destroy_user_session_path
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
