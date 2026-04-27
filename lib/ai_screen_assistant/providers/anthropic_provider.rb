# frozen_string_literal: true

require "faraday"
require "json"

module AiScreenAssistant
  module Providers
    class AnthropicProvider < Provider
      DEFAULT_BASE = "https://api.anthropic.com/v1"
      DEFAULT_MODEL = "claude-3-5-haiku-20241022"

      def initialize(model: DEFAULT_MODEL, base_url: nil, timeout: 60)
        @model = model
        @base_url = (base_url || DEFAULT_BASE).to_s.chomp("/")
        @timeout = timeout
      end

      def complete(messages:, credentials:, tools: nil, model: nil, **)
        api_key = credentials[:api_key] || credentials["api_key"]
        raise ConfigurationError, "Anthropic credentials missing :api_key" if api_key.nil? || api_key.to_s.empty?

        system, anthropic_messages = split_system_user(messages)

        conn = Faraday.new(url: @base_url) do |f|
          f.adapter Faraday.default_adapter
          f.options.timeout = @timeout
          f.options.open_timeout = @timeout
        end

        body = {
          model: model || @model,
          max_tokens: credentials[:max_tokens] || credentials["max_tokens"] || 4096,
          system: system,
          messages: anthropic_messages
        }

        response = conn.post("messages") do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["x-api-key"] = api_key
          req.headers["anthropic-version"] = "2023-06-01"
          req.body = JSON.generate(body)
        end

        unless response.success?
          raise ProviderError, "Anthropic HTTP #{response.status}: #{response.body.inspect}"
        end

        data = JSON.parse(response.body)
        block = data.dig("content", 0)
        text = block && block["type"] == "text" ? block["text"] : nil
        raise ProviderError, "Anthropic empty content: #{data.inspect}" if text.nil? || text.to_s.empty?

        CompletionResult.new(
          text: text.to_s,
          model: data["model"],
          usage: {
            "input_tokens" => data["usage"]&.dig("input_tokens"),
            "output_tokens" => data["usage"]&.dig("output_tokens")
          },
          raw_response: data
        )
      end

      private

      def split_system_user(messages)
        system_parts = []
        out = []
        messages.each do |m|
          h = (m.is_a?(Hash) ? m : m.to_h).transform_keys(&:to_s)
          role = h["role"]
          content = h["content"].to_s
          case role
          when "system"
            system_parts << content
          when "user"
            out << { "role" => "user", "content" => content }
          when "assistant"
            out << { "role" => "assistant", "content" => content }
          end
        end
        [system_parts.join("\n\n"), out]
      end
    end
  end
end
