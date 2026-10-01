require "test_helper"

class WelcomeEmailFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "signing up enqueues a welcome email to the new user" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post user_registration_path, params: {
        user: {
          username: "welcomed",
          email: "welcomed@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "the welcome email is addressed correctly and greets the user" do
    user = User.create!(email: "welcomed@example.com", password: "password123",
      username: "welcomed")

    mail = UserMailer.welcome(user)

    assert_equal [ "welcomed@example.com" ], mail.to
    assert_equal "Welcome to Odinbook, welcomed!", mail.subject
    assert_match "go set it up", mail.text_part.body.to_s
  end

  test "signing in does not send another welcome email" do
    user = users(:alice)

    assert_no_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      post user_session_path, params: {
        user: { email: user.email, password: "password" }
      }
    end
  end
end
