# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::JobMethodLength, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/JobMethodLength" => {
        "Enabled" => true,
        "Max" => 7,
        "AllowedMethods" => [],
        "Include" => ["**/app/jobs/**/*.rb"],
        "Exclude" => ["**/app/jobs/application_job.rb"],
      }
    )
  end

  context "when in a job file" do
    let(:source_file) { "app/jobs/onboard_user_job.rb" }

    it "registers an offense for a method exceeding the max" do
      expect_offense(<<~RUBY, source_file)
        def perform(user_id)
        ^^^^^^^^^^^^^^^^^^^^ [Harness] `perform` is 8 lines (max 7). Jobs should be thin. Delegate to a service object in app/services/.
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
        end
      RUBY
    end

    it "does not register an offense for a method at exactly the max" do
      expect_no_offenses(<<~RUBY, source_file)
        def perform(user_id)
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
        end
      RUBY
    end

    it "does not register an offense for a short method" do
      expect_no_offenses(<<~RUBY, source_file)
        def perform(user_id)
          user = User.find(user_id)
          OnboardUserService.new(user).call
        end
      RUBY
    end

    it "does not count blank lines and comments" do
      expect_no_offenses(<<~RUBY, source_file)
        def perform(user_id)
          user = User.find(user_id)

          # delegate to service
          result = OnboardUserService.new(user).call

          result
        end
      RUBY
    end

    it "flags non-perform methods too" do
      expect_offense(<<~RUBY, source_file)
        def some_helper
        ^^^^^^^^^^^^^^^ [Harness] `some_helper` is 8 lines (max 7). Jobs should be thin. Delegate to a service object in app/services/.
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
        end
      RUBY
    end
  end

  context "when in application_job.rb" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/jobs/application_job.rb")
        def perform(args)
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
        end
      RUBY
    end
  end

  context "when in a non-job file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/user.rb")
        def perform
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
        end
      RUBY
    end
  end

  context "with custom Max" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/JobMethodLength" => {
          "Enabled" => true,
          "Max" => 3,
          "AllowedMethods" => [],
          "Include" => ["**/app/jobs/**/*.rb"],
          "Exclude" => ["**/app/jobs/application_job.rb"],
        }
      )
    end

    it "uses the configured max" do
      expect_offense(<<~RUBY, "app/jobs/send_email_job.rb")
        def perform(user_id)
        ^^^^^^^^^^^^^^^^^^^^ [Harness] `perform` is 4 lines (max 3). Jobs should be thin. Delegate to a service object in app/services/.
          user = User.find(user_id)
          email = build_email(user)
          email.deliver_later
          log_delivery(user)
        end
      RUBY
    end
  end

  context "with AllowedMethods" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/JobMethodLength" => {
          "Enabled" => true,
          "Max" => 7,
          "AllowedMethods" => %w[perform],
          "Include" => ["**/app/jobs/**/*.rb"],
          "Exclude" => ["**/app/jobs/application_job.rb"],
        }
      )
    end

    it "does not register an offense for allowed methods" do
      expect_no_offenses(<<~RUBY, "app/jobs/send_email_job.rb")
        def perform(user_id)
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
        end
      RUBY
    end
  end
end
