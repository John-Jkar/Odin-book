require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "comment belongs to a user and a post" do
    comment = comments(:bob_on_alice)

    assert_equal users(:bob), comment.user
    assert_equal posts(:alice_post), comment.post
    assert_includes posts(:alice_post).comments, comment
    assert_includes users(:bob).comments, comment
  end

  test "content must be present" do
    comment = Comment.new(user: users(:bob), post: posts(:alice_post), content: "")

    assert_not comment.valid?
    assert_includes comment.errors[:content], "can't be blank"
  end

  test "comment requires a user and a post" do
    assert_not Comment.new(content: "hi").valid?
    assert_not Comment.new(content: "hi", user: users(:bob)).valid?
  end

  test "chronological scope orders oldest first" do
    post = posts(:bob_post)
    post.comments.create!(user: users(:carol), content: "First comment")
    post.comments.create!(user: users(:carol), content: "Second comment")

    contents = post.comments.chronological.pluck(:content)

    assert_equal "First comment", contents[-2]
    assert_equal "Second comment", contents[-1]
  end

  test "destroying a post destroys its comments" do
    post = posts(:alice_post)
    assert_difference "Comment.count", -1 do
      post.destroy!
    end
  end
end
