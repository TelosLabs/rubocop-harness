# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::NoQueriesInControllers, :config do
  let(:config) do
    RuboCop::Config.new(
      "Harness/NoQueriesInControllers" => {
        "Enabled" => true,
        "AllowedMethods" => %w[find find_by],
        "Include" => ["**/app/controllers/**/*.rb"],
        "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
      }
    )
  end

  let(:source_file) { "app/controllers/users_controller.rb" }

  context "with ActiveRecord query methods" do
    it "registers an offense for `where`" do
      expect_offense(<<~RUBY, source_file)
        def index
          @users = User.where(active: true)
                        ^^^^^ [Harness] `where` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end

    it "registers an offense for `order`" do
      expect_offense(<<~RUBY, source_file)
        def index
          @users = User.order(:name)
                        ^^^^^ [Harness] `order` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end

    it "registers an offense for `joins`" do
      expect_offense(<<~RUBY, source_file)
        def index
          @users = User.joins(:posts)
                        ^^^^^ [Harness] `joins` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end

    it "registers an offense for `includes`" do
      expect_offense(<<~RUBY, source_file)
        def index
          @users = User.includes(:posts)
                        ^^^^^^^^ [Harness] `includes` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end

    it "registers an offense for `destroy_all`" do
      expect_offense(<<~RUBY, source_file)
        def destroy
          User.destroy_all
               ^^^^^^^^^^^ [Harness] `destroy_all` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end

    it "registers an offense for `pluck`" do
      expect_offense(<<~RUBY, source_file)
        def index
          @names = User.pluck(:name)
                        ^^^^^ [Harness] `pluck` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end
  end

  context "with allowed methods" do
    it "does not register an offense for `find`" do
      expect_no_offenses(<<~RUBY, source_file)
        def show
          @user = User.find(params[:id])
        end
      RUBY
    end

    it "does not register an offense for `find_by`" do
      expect_no_offenses(<<~RUBY, source_file)
        def show
          @user = User.find_by(slug: params[:slug])
        end
      RUBY
    end
  end

  context "with chained queries" do
    it "registers an offense for each query method in the chain" do
      expect_offense(<<~RUBY, source_file)
        def index
          @users = User.where(active: true).order(:name).limit(10)
                                                         ^^^^^ [Harness] `limit` query in controller. [...]
                                            ^^^^^ [Harness] `order` query in controller. [...]
                        ^^^^^ [Harness] `where` query in controller. [...]
        end
      RUBY
    end
  end

  context "with method calls without receiver" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, source_file)
        def index
          where(active: true)
        end
      RUBY
    end
  end

  context "when in a concern file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/controllers/concerns/filterable.rb")
        def apply_filters
          User.where(active: true)
        end
      RUBY
    end
  end

  context "when in a non-controller file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY, "app/services/user_search.rb")
        def call
          User.where(active: true)
        end
      RUBY
    end
  end

  context "when AllowedMethods is empty" do
    let(:config) do
      RuboCop::Config.new(
        "Harness/NoQueriesInControllers" => {
          "Enabled" => true,
          "AllowedMethods" => [],
          "Include" => ["**/app/controllers/**/*.rb"],
          "Exclude" => ["**/app/controllers/concerns/**/*.rb"],
        }
      )
    end

    it "registers an offense for find" do
      expect_offense(<<~RUBY, source_file)
        def show
          @user = User.find(params[:id])
                       ^^^^ [Harness] `find` query in controller. Move query logic to a model scope or query object.
        end
      RUBY
    end
  end
end
