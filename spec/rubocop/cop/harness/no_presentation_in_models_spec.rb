# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::NoPresentationInModels, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/NoPresentationInModels" => {
        "Enabled" => true,
        "AllowedMethods" => [],
        "Include" => ["**/app/models/**/*.rb"],
        "Exclude" => ["**/app/models/concerns/**/*.rb"],
      }
    )
  end

  let(:source_file) { "app/models/user.rb" }

  context "with HTML generation methods" do
    it "registers an offense for content_tag" do
      expect_offense(<<~RUBY, source_file)
        def badge
          content_tag(:span, role_name, class: "badge")
          ^^^^^^^^^^^ [Harness] `content_tag` is presentation logic in a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end

    it "registers an offense for link_to" do
      expect_offense(<<~RUBY, source_file)
        def profile_link
          link_to(name, "/users/\#{id}")
          ^^^^^^^ [Harness] `link_to` is presentation logic in a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end

    it "registers an offense for sanitize" do
      expect_offense(<<~RUBY, source_file)
        def clean_bio
          sanitize(bio)
          ^^^^^^^^ [Harness] `sanitize` is presentation logic in a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end
  end

  context "with route helpers include" do
    it "registers an offense for including url_helpers" do
      expect_offense(<<~RUBY, source_file)
        class User < ApplicationRecord
          include Rails.application.routes.url_helpers
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [Harness] `Rails.application.routes.url_helpers` brings presentation logic into a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end
  end

  context "with ActionController::Base.helpers" do
    it "registers an offense for helpers usage" do
      expect_offense(<<~RUBY, source_file)
        def formatted_price
          ActionController::Base.helpers.number_to_currency(price)
                                         ^^^^^^^^^^^^^^^^^^ [Harness] `ActionController::Base.helpers` is presentation logic in a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end
  end

  context "with legitimate model methods" do
    it "does not flag to_s" do
      expect_no_offenses(<<~'RUBY', source_file)
        def to_s
          "#{first_name} #{last_name}"
        end
      RUBY
    end

    it "does not flag display_name" do
      expect_no_offenses(<<~'RUBY', source_file)
        def display_name
          "#{first_name} #{last_name}"
        end
      RUBY
    end

    it "does not flag to_param" do
      expect_no_offenses(<<~RUBY, source_file)
        def to_param
          slug
        end
      RUBY
    end

    it "does not flag avatar_url" do
      expect_no_offenses(<<~'RUBY', source_file)
        def avatar_url
          "https://example.com/avatars/#{id}.png"
        end
      RUBY
    end

    it "does not flag file_path" do
      expect_no_offenses(<<~RUBY, source_file)
        def file_path
          Rails.root.join("uploads", filename)
        end
      RUBY
    end
  end

  context "when in a concern file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/models/concerns/displayable.rb")
        def badge
          content_tag(:span, role_name, class: "badge")
        end
      RUBY
    end
  end

  context "when in a non-model file" do
    it "does not register an offense in a controller" do
      expect_no_offenses(<<~RUBY, "app/controllers/users_controller.rb")
        def badge
          content_tag(:span, "admin", class: "badge")
        end
      RUBY
    end

    it "does not register an offense in a helper" do
      expect_no_offenses(<<~RUBY, "app/helpers/users_helper.rb")
        def user_badge(user)
          content_tag(:span, user.role_name, class: "badge")
        end
      RUBY
    end
  end

  context "with AllowedMethods" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/NoPresentationInModels" => {
          "Enabled" => true,
          "AllowedMethods" => %w[content_tag],
          "Include" => ["**/app/models/**/*.rb"],
          "Exclude" => ["**/app/models/concerns/**/*.rb"],
        }
      )
    end

    it "does not register an offense for allowed methods" do
      expect_no_offenses(<<~RUBY, source_file)
        def badge
          content_tag(:span, role_name, class: "badge")
        end
      RUBY
    end

    it "still flags non-allowed methods" do
      expect_offense(<<~RUBY, source_file)
        def profile_link
          link_to(name, "/users/\#{id}")
          ^^^^^^^ [Harness] `link_to` is presentation logic in a model. Move to a presenter, decorator, or view helper.
        end
      RUBY
    end
  end
end
