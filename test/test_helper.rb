ENV["RAILS_ENV"] ||= "test"

# Ensure the test database exists: if missing, auto-run db:prepare and retry.
begin
  require_relative "../config/environment"
rescue => e
  raise unless e.instance_of?(ActiveRecord::NoDatabaseError)

  warn "[test] Database not found. Running `bin/rails db:prepare` for test environment..."
  system({"RAILS_ENV" => "test"}, "bin/rails db:prepare")
  require_relative "../config/environment"
end

require "rails/test_help"

Geocoder.configure(lookup: :test, ip_lookup: :test)
Geocoder::Lookup::Test.set_default_stub([
  {
    "coordinates" => [44.501, -73.199],
    "address" => "Colchester, VT, USA",
    "state" => "Vermont",
    "state_code" => "VT",
    "country" => "United States",
    "country_code" => "US"
  }
])

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    self.use_transactional_tests = true

    def sign_in_as(user)
      # Step 1: Send login email and generate a login code
      # Ensure a clean mailbox for reliable extraction
      ActionMailer::Base.deliveries.clear

      post session_path, params: {email: user.email}
      assert_response :redirect

      # Extract the generated login code from the last delivered email
      mail = ActionMailer::Base.deliveries.last
      raise "No login email sent" unless mail

      body_text = [mail.subject, mail.text_part&.body&.to_s, mail.html_part&.body&.to_s,
        mail.body&.to_s].compact.join("\n")
      code_match = body_text.match(/\b\d{6}\b/)
      raise "Login code not found in email" unless code_match

      code = code_match[0]

      # Step 2: Confirm login
      post confirm_session_path, params: {
        email: user.email,
        code: code
      }
      assert_response :redirect

      user
    end
  end
end
