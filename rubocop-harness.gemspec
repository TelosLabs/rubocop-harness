# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "rubocop/harness/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-harness"
  spec.version = RuboCop::Harness::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 3.1.0"
  spec.authors = ["Telos Labs"]
  spec.email = ["dev@teloslabs.co"]
  spec.summary = "RuboCop cops for AI-assisted Rails development."
  spec.description = "Architectural boundary enforcement for Rails apps with " \
                     "agent-readable remediation messages. Part of the harness " \
                     "engineering toolkit."
  spec.homepage = "https://github.com/TelosLabs/rubocop-harness"
  spec.license = "MIT"

  spec.files = Dir["lib/**/*", "config/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true",
    "default_lint_roller_plugin" => "RuboCop::Harness::Plugin",
  }

  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", ">= 1.75.0", "< 2.0"
end
