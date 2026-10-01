require "test_helper"

class RelationshipTest < ActiveSupport::TestCase
  test "relationship links two users" do
    relationship = relationships(:alice_follows_bob)

    assert_equal users(:alice), relationship.follower
    assert_equal users(:bob), relationship.following
  end

  test "default status is pending" do
    relationship = Relationship.create!(follower: users(:carol), following: users(:bob))

    assert relationship.pending?
    assert_not relationship.accepted?
  end

  test "accept! moves the request to accepted" do
    relationship = relationships(:carol_requests_alice)

    assert_difference -> { users(:alice).followers.count }, 1 do
      relationship.accept!
    end

    assert relationship.accepted?
    assert users(:carol).following?(users(:alice))
  end

  test "status must be pending or accepted" do
    relationship = Relationship.new(follower: users(:alice), following: users(:carol),
      status: "maybe")

    assert_not relationship.valid?
    assert_predicate relationship.errors[:status], :any?
  end

  test "cannot follow yourself" do
    relationship = Relationship.new(follower: users(:alice), following: users(:alice))

    assert_not relationship.valid?
  end

  test "the same pair cannot be requested twice" do
    duplicate = Relationship.new(follower: users(:alice), following: users(:bob))

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:follower_id], :any?
  end

  test "a reverse relationship is allowed" do
    # alice follows bob and bob follows alice: two distinct, valid rows.
    assert_includes users(:alice).following, users(:bob)
    assert_includes users(:bob).following, users(:alice)

    fresh = Relationship.new(follower: users(:carol), following: users(:bob))
    assert fresh.valid?
  end

  test "accepted scope only returns accepted relationships" do
    assert_includes Relationship.accepted, relationships(:alice_follows_bob)
    assert_not_includes Relationship.accepted, relationships(:carol_requests_alice)

    assert_includes Relationship.pending, relationships(:carol_requests_alice)
  end
end
