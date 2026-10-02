require "test_helper"

# Capybara's default wait is 2s, which is tight for Turbo form submissions on a
# loaded CI runner. These are timing-sensitive assertions about DOM state that
# arrives asynchronously, so allow more headroom rather than assert instantly.
Capybara.default_max_wait_time = Integer(ENV.fetch("CAPYBARA_WAIT", 15))
Capybara.server = :puma, { Silent: true }

# Registered explicitly (rather than using `driven_by :selenium, using:
# :headless_chrome`) so the driver can use the `eager` page-load strategy.
# Otherwise a slow or unreachable Gravatar request stalls page load and the
# tests time out for reasons unrelated to the app.
Capybara.register_driver :odinbook_headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--disable-search-engine-choice-screen")
  options.add_argument("--window-size=1400,1600")
  options.page_load_strategy = :eager
  # Lets a machine with a locally installed Chromium/chrome pair opt in when
  # the driver on PATH does not match the default browser.
  options.binary = ENV["CHROME_BINARY"] if ENV["CHROME_BINARY"].present?

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :odinbook_headless_chrome

  # Each system test drives a real browser, so run them one at a time instead
  # of forking a server per worker.
  parallelize(workers: 1)

  # Matches the password used by the encrypted_password fixture in
  # test/fixtures/users.yml. The db/seeds.rb accounts use "password123".
  DEFAULT_PASSWORD = "password"

  def sign_in_as(username, password: DEFAULT_PASSWORD)
    visit new_user_session_path
    fill_in "Email", with: "#{username}@example.com"
    fill_in "Password", with: password
    click_button "Log in"
    assert_selector ".navbar", wait: 10
  end

  def sign_out
    click_button "Log out"
    # Devise redirects to root, which is the landing page for signed out
    # visitors.
    assert_selector ".landing-title", wait: 10
  end
end
