# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "open_ai" => "OpenAI",
  "json_envelope" => "JSONEnvelope"
)
loader.setup

module AiScreenAssistant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ProviderError < Error; end
end

loader.eager_load
