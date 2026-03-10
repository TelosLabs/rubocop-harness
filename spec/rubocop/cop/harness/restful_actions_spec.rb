# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::RestfulActions, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/RestfulActions" => {
        "Enabled" => true,
        "AllowedMethods" => [],
        "Include" => ["**/app/controllers/**/*.rb"],
        "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
      }
    )
  end

  let(:source_file) { "app/controllers/users_controller.rb" }

  context "with standard RESTful actions" do
    %w[index show new create edit update destroy].each do |action|
      it "does not register an offense for `#{action}`" do
        expect_no_offenses(<<~RUBY, source_file)
          class UsersController < ApplicationController
            def #{action}
              # ...
            end
          end
        RUBY
      end
    end
  end

  context "with non-standard actions" do
    it "registers an offense for a non-RESTful public action" do
      expect_offense(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def archive
          ^^^^^^^^^^^ [Harness] `archive` is not a standard RESTful action. [...]
          end
        end
      RUBY
    end

    it "registers an offense for multiple non-RESTful actions" do
      expect_offense(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def index
          end

          def archive
          ^^^^^^^^^^^ [Harness] `archive` is not a standard RESTful action. [...]
          end

          def bulk_update
          ^^^^^^^^^^^^^^^ [Harness] `bulk_update` is not a standard RESTful action. [...]
          end
        end
      RUBY
    end
  end

  context "with private methods" do
    it "does not register an offense for private methods" do
      expect_no_offenses(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def index
          end

          private

          def set_user
            @user = User.find(params[:id])
          end

          def user_params
            params.expect(user: [:name, :email])
          end
        end
      RUBY
    end

    it "does not register an offense for inline private methods" do
      expect_no_offenses(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def index
          end

          private def set_user
            @user = User.find(params[:id])
          end
        end
      RUBY
    end
  end

  context "with protected methods" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, source_file)
        class UsersController < ApplicationController
          protected

          def helper_method
          end
        end
      RUBY
    end
  end

  context "with AllowedMethods configured" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/RestfulActions" => {
          "Enabled" => true,
          "AllowedMethods" => ["search"],
          "Include" => ["**/app/controllers/**/*.rb"],
          "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
        }
      )
    end

    it "does not register an offense for allowed methods" do
      expect_no_offenses(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def search
          end
        end
      RUBY
    end

    it "still registers an offense for other non-RESTful actions" do
      expect_offense(<<~RUBY, source_file)
        class UsersController < ApplicationController
          def archive
          ^^^^^^^^^^^ [Harness] `archive` is not a standard RESTful action. [...]
          end
        end
      RUBY
    end
  end

  context "when in a concern file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/controllers/concerns/searchable.rb")
        module Searchable
          def search
          end
        end
      RUBY
    end
  end

  context "when in a non-controller file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/user.rb")
        class User < ApplicationRecord
          def archive
          end
        end
      RUBY
    end
  end
end
