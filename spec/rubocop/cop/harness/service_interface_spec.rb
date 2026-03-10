# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::ServiceInterface, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/ServiceInterface" => {
        "Enabled" => true,
        "RequiredMethods" => %w[call save],
        "Include" => ["**/app/services/**/*.rb"],
        "Exclude" => ["**/app/services/application_service.rb"],
      }
    )
  end

  let(:source_file) { "app/services/order_processor.rb" }

  context "when the service defines `call`" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
          def call
            # process order
          end
        end
      RUBY
    end
  end

  context "when the service defines `save`" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
          def save
            # persist order
          end
        end
      RUBY
    end
  end

  context "when the service defines both" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
          def call
          end

          def save
          end
        end
      RUBY
    end
  end

  context "when the service defines neither" do
    it "registers an offense" do
      expect_offense(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
              ^^^^^^^^^^^^^^ [Harness] `OrderProcessor` does not define a `call` or `save` method. Service objects must implement Pattern A (call) or Pattern B (save).
          def process
            # not a standard interface
          end
        end
      RUBY
    end
  end

  context "when the service is empty" do
    it "registers an offense" do
      expect_offense(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
              ^^^^^^^^^^^^^^ [Harness] `OrderProcessor` does not define a `call` or `save` method. Service objects must implement Pattern A (call) or Pattern B (save).
        end
      RUBY
    end
  end

  context "when the class has only one method (single-child body)" do
    it "detects call correctly" do
      expect_no_offenses(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
          def call
          end
        end
      RUBY
    end

    it "flags a single non-matching method" do
      expect_offense(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
              ^^^^^^^^^^^^^^ [Harness] `OrderProcessor` does not define a `call` or `save` method. Service objects must implement Pattern A (call) or Pattern B (save).
          def execute
          end
        end
      RUBY
    end
  end

  context "with nested classes" do
    it "only checks the top-level class" do
      expect_no_offenses(<<~RUBY, source_file)
        class OrderProcessor < ApplicationService
          class Result
            def initialize(data)
              @data = data
            end
          end

          def call
          end
        end
      RUBY
    end
  end

  context "when in application_service.rb" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/services/application_service.rb")
        class ApplicationService
          def call
            raise NotImplementedError
          end
        end
      RUBY
    end
  end

  context "when in a non-service file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/user.rb")
        class User < ApplicationRecord
          def process
          end
        end
      RUBY
    end
  end
end
