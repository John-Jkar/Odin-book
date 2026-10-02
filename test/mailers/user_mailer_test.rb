require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome is addressed to the user and greets them by username" do
    user = users(:alice)
    mail = UserMailer.welcome(user)

    assert_equal [ user.email ], mail.to
    assert_equal "Welcome to Odinbook, alice!", mail.subject
    assert_match "alice", mail.text_part.body.to_s
    assert_match "alice", mail.html_part.body.to_s
  end

  test "welcome links to the profile editor" do
    mail = UserMailer.welcome(users(:alice))

    assert_match "http://example.com/profile/edit", mail.text_part.body.to_s
  end

  test "the plain text part carries no HTML markup" do
    body = UserMailer.welcome(users(:alice)).text_part.body.to_s

    assert_no_match(/<[a-z]/i, body)
    assert_match "http://example.com/profile/edit", body
  end

  test "welcome is delivered for a newly created user" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      UserMailer.welcome(users(:alice)).deliver_now
    end
  end
end
