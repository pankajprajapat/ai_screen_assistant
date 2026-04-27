# frozen_string_literal: true

module AiScreenAssistant
  module Providers
    class StubProvider < Provider
      def initialize(default_text: "stub reply", usage: {})
        @default_text = default_text
        @usage = usage
      end

      def complete(messages:, credentials:, tools: nil, model: nil, **)
        last = messages.reverse.find { |m| m[:role] == "user" || m["role"] == "user" }
        user_text = last ? (last[:content] || last["content"]).to_s : ""
        text = user_text.empty? ? @default_text : "#{@default_text}: #{user_text}"
        CompletionResult.new(text: text, model: model || "stub", usage: @usage, raw_response: { "stub" => true })
      end
    end
  end
end
