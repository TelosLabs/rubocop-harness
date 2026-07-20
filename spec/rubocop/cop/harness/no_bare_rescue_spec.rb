# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Harness::NoBareRescue, :config do
  let(:config) do
    RuboCop::Config.new(
      'Harness/NoBareRescue' => {
        'Enabled' => true,
        'Include' => ['**/app/**/*.rb', '**/lib/**/*.rb']
      }
    )
  end

  let(:source_file) { 'app/controllers/dashboards_controller.rb' }

  context 'with a sole blanket rescue' do
    it 'registers an offense for a class-less rescue with a variable' do
      expect_offense(<<~RUBY, source_file)
        def load_dashboard
          fetch_data
        rescue => e
        ^^^^^^ [Harness] Blanket rescue catches every `StandardError`. Rescue the specific error class you expect (e.g. `rescue Faraday::Error => e`). A blanket rescue is allowed only as a backstop after a specific rescue clause.
          Rollbar.error(e)
        end
      RUBY
    end

    it 'registers an offense for a class-less rescue without a variable' do
      expect_offense(<<~RUBY, source_file)
        def load_dashboard
          fetch_data
        rescue
        ^^^^^^ [Harness] Blanket rescue catches every `StandardError`. Rescue the specific error class you expect (e.g. `rescue Faraday::Error => e`). A blanket rescue is allowed only as a backstop after a specific rescue clause.
          @data = nil
        end
      RUBY
    end

    it 'registers an offense for an explicit StandardError rescue' do
      expect_offense(<<~RUBY, source_file)
        begin
          fetch_data
        rescue StandardError => e
        ^^^^^^ [Harness] Blanket rescue catches every `StandardError`. Rescue the specific error class you expect (e.g. `rescue Faraday::Error => e`). A blanket rescue is allowed only as a backstop after a specific rescue clause.
          Rollbar.error(e)
        end
      RUBY
    end

    it 'registers an offense for an explicit Exception rescue' do
      expect_offense(<<~RUBY, source_file)
        begin
          fetch_data
        rescue Exception => e
        ^^^^^^ [Harness] Blanket rescue catches every `StandardError`. Rescue the specific error class you expect (e.g. `rescue Faraday::Error => e`). A blanket rescue is allowed only as a backstop after a specific rescue clause.
          Rollbar.error(e)
        end
      RUBY
    end

    it 'registers an offense for a fully-qualified StandardError rescue' do
      expect_offense(<<~RUBY, source_file)
        begin
          fetch_data
        rescue ::StandardError => e
        ^^^^^^ [Harness] Blanket rescue catches every `StandardError`. Rescue the specific error class you expect (e.g. `rescue Faraday::Error => e`). A blanket rescue is allowed only as a backstop after a specific rescue clause.
          Rollbar.error(e)
        end
      RUBY
    end
  end

  context 'with a specific rescue' do
    it 'does not register an offense for a single specific class' do
      expect_no_offenses(<<~RUBY, source_file)
        begin
          fetch_data
        rescue Faraday::Error => e
          Rollbar.error(e)
        end
      RUBY
    end

    it 'does not register an offense for multiple specific classes' do
      expect_no_offenses(<<~RUBY, source_file)
        begin
          fetch_data
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
          Rollbar.error(e)
        end
      RUBY
    end
  end

  context 'with a blanket rescue used as a backstop' do
    it 'does not register an offense when preceded by a specific clause' do
      expect_no_offenses(<<~RUBY, source_file)
        begin
          fetch_data
        rescue Faraday::Error => e
          retry_later(e)
        rescue => e
          Rollbar.error(e)
        end
      RUBY
    end

    it 'does not register an offense for an explicit StandardError backstop' do
      expect_no_offenses(<<~RUBY, source_file)
        begin
          fetch_data
        rescue ActiveRecord::RecordNotFound => e
          head :not_found
        rescue StandardError => e
          Rollbar.error(e)
        end
      RUBY
    end

    it 'does not flag a resbody that mixes a broad and a specific class' do
      expect_no_offenses(<<~RUBY, source_file)
        begin
          fetch_data
        rescue StandardError, Faraday::Error => e
          Rollbar.error(e)
        end
      RUBY
    end
  end

  context 'with a non-Rails-layer file' do
    it 'does not register an offense outside the Include paths' do
      expect_no_offenses(<<~RUBY, 'spec/models/user_spec.rb')
        begin
          fetch_data
        rescue => e
          Rollbar.error(e)
        end
      RUBY
    end
  end
end
