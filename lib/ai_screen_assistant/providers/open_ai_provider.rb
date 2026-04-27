# frozen_string_literal: true

require "faraday"
require "json"

module AiScreenAssistant
  module Providers
    class OpenAiProvider < Provider
      DEFAULT_BASE = "https://api.openai.com/v1"
      DEFAULT_MODEL = "gpt-4o-mini"

      def initialize(model: DEFAULT_MODEL, base_url: nil, timeout: 60)
        @model = model
        @base_url = (base_url || DEFAULT_BASE).to_s.chomp("/")
        @timeout = timeout
      end

      def complete(messages:, credentials:, tools: nil, model: nil, **)
        api_key = credentials[:api_key] || credentials["api_key"]
        raise ConfigurationError, "OpenAI credentials missing :api_key" if api_key.nil? || api_key.to_s.empty?

        conn = Faraday.new(url: @base_url) do |f|
          f.adapter Faraday.default_adapter
          f.options.timeout = @timeout
          f.options.open_timeout = @timeout
        end

        body = {
          model: model || @model,
          messages: normalize_messages(messages)
        }
        body[:tools] = tools if tools

        response = conn.post("chat/completions") do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["Authorization"] = "Bearer #{api_key}"
          org = credentials[:organization_id] || credentials["organization_id"]
          req.headers["OpenAI-Organization"] = org if org && !org.to_s.empty?
          req.body = JSON.generate(body)
        end

        unless response.success?
          raise ProviderError, "OpenAI HTTP #{response.status}: #{response.body.inspect}"
        end

        data = JSON.parse(response.body)
        choice = data.dig("choices", 0, "message")
        text = choice&.fetch("content", nil)
        raise ProviderError, "OpenAI empty content: #{data.inspect}" if text.nil? || text.to_s.empty?

        CompletionResult.new(
          text: text.to_s,
          model: data["model"],
          usage: data["usage"] || {},
          raw_response: data
        )
      end

      private

      def normalize_messages(messages)
        messages.map do |m|
          h = (m.is_a?(Hash) ? m : m.to_h).transform_keys(&:to_s)
          { "role" => h["role"], "content" => h["content"].to_s }
        end
      end
    end
  end
end
