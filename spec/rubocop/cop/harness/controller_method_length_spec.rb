# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::ControllerMethodLength, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/ControllerMethodLength" => {
        "Enabled" => true,
        "Max" => 10,
        "Include" => ["**/app/controllers/**/*.rb"],
        "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
      }
    )
  end

  context "when in a controller file" do
    let(:source_file) { "app/controllers/users_controller.rb" }

    it "registers an offense for a method exceeding the max" do
      expect_offense(<<~RUBY, source_file)
        def create
        ^^^^^^^^^^ [Harness] `create` is 11 lines (max 10). Extract logic into a service object in app/services/. Use Pattern A (call) or Pattern B (save).
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
          i = 9
          j = 10
          k = 11
        end
      RUBY
    end

    it "does not register an offense for a method at exactly the max" do
      expect_no_offenses(<<~RUBY, source_file)
        def create
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
          i = 9
          j = 10
        end
      RUBY
    end

    it "does not register an offense for a short method" do
      expect_no_offenses(<<~RUBY, source_file)
        def create
          @user = User.new
        end
      RUBY
    end

    it "does not count blank lines and comments" do
      expect_no_offenses(<<~RUBY, source_file)
        def create
          a = 1

          # a comment
          b = 2

          c = 3
          d = 4
          e = 5
        end
      RUBY
    end

    it "does not register an offense for an empty method" do
      expect_no_offenses(<<~RUBY, source_file)
        def create
        end
      RUBY
    end

    it "includes remediation guidance in the message" do
      expect_offense(<<~RUBY, source_file)
        def create
        ^^^^^^^^^^ [Harness] `create` is 11 lines (max 10). Extract logic into a service object in app/services/. Use Pattern A (call) or Pattern B (save).
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
          i = 9
          j = 10
          k = 11
        end
      RUBY
    end
  end

  context "when in a controller concern file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/controllers/concerns/authenticatable.rb")
        def long_method
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
          i = 9
          j = 10
          k = 11
        end
      RUBY
    end
  end

  context "when in a non-controller file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/user.rb")
        def long_method
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
          g = 7
          h = 8
          i = 9
          j = 10
          k = 11
        end
      RUBY
    end
  end

  context "when Max is configured" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/ControllerMethodLength" => {
          "Enabled" => true,
          "Max" => 5,
          "Include" => ["**/app/controllers/**/*.rb"],
          "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
        }
      )
    end

    it "uses the configured max" do
      expect_offense(<<~RUBY, "app/controllers/users_controller.rb")
        def create
        ^^^^^^^^^^ [Harness] `create` is 6 lines (max 5). Extract logic into a service object in app/services/. Use Pattern A (call) or Pattern B (save).
          a = 1
          b = 2
          c = 3
          d = 4
          e = 5
          f = 6
        end
      RUBY
    end
  end
end
