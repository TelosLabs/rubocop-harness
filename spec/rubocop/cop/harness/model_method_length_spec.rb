# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::ModelMethodLength, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/ModelMethodLength" => {
        "Enabled" => true,
        "Max" => 7,
        "Include" => ["**/app/models/**/*.rb"],
        "Exclude" => ["**/app/models/concerns/**/*.rb"],
      }
    )
  end

  context "when in a model file" do
    let(:source_file) { "app/models/user.rb" }

    it "registers an offense for a method exceeding the max" do
      expect_offense(<<~RUBY, source_file)
        def calculate_score
        ^^^^^^^^^^^^^^^^^^^ [Harness] `calculate_score` is 8 lines (max 7). Decompose into smaller methods, concerns, or value objects.
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
        def calculate_score
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
      expect_no_offenses(<<~'RUBY', source_file)
        def full_name
          "#{first_name} #{last_name}"
        end
      RUBY
    end

    it "does not count blank lines and comments" do
      expect_no_offenses(<<~RUBY, source_file)
        def calculate_score
          a = 1

          # a comment
          b = 2

          c = 3
          d = 4
        end
      RUBY
    end
  end

  context "when in a model concern file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/concerns/trackable.rb")
        def long_method
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

  context "when in a non-model file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/controllers/users_controller.rb")
        def long_method
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
