# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ai_screen_assistant/version"

Gem::Specification.new do |spec|
  spec.name = "ai_screen_assistant"
  spec.version = AiScreenAssistant::VERSION
  spec.authors = ["pankajkumar.jec@gmail.com"]
  spec.summary = "Screen-grounded AI chat with pluggable LLM providers and conversation storage"
  spec.homepage = "https://github.com/pankajprajapat/ai_screen_assistant"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"].select { |f| File.file?(f) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "zeitwerk", "~> 2.6"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "webmock", "~> 3.0"
end
