# frozen_string_literal: true

module AiScreenAssistant
  module Providers
    # AWS Bedrock Converse API. Add to your application Gemfile:
    #   gem "aws-sdk-bedrockruntime", "~> 1"
    class BedrockProvider < Provider
      def initialize(model_id:, region: nil, timeout: nil)
        @model_id = model_id
        @region = region
        @timeout = timeout
      end

      def complete(messages:, credentials:, tools: nil, model: nil, **)
        begin
          require "aws-sdk-bedrockruntime"
        rescue LoadError
          raise ConfigurationError,
                "BedrockProvider requires the aws-sdk-bedrockruntime gem in your Gemfile"
        end

        client = Aws::BedrockRuntime::Client.new(
          region: @region || credentials[:region] || credentials["region"] || ENV["AWS_REGION"],
          credentials: credentials[:aws_credentials] || credentials["aws_credentials"],
          http_read_timeout: @timeout || 120
        )

        system, msgs = split_messages(messages)
        converse_msgs = msgs.map do |m|
          { role: normalize_role(m[:role] || m["role"]), content: [{ text: (m[:content] || m["content"]).to_s }] }
        end

        params = {
          model_id: model || @model_id,
          messages: converse_msgs,
          system: (system.empty? ? nil : [{ text: system }])
        }.compact

        resp = client.converse(params)
        text = extract_text(resp)
        raise ProviderError, "Bedrock empty output: #{resp.to_h.inspect}" if text.nil? || text.empty?

        CompletionResult.new(
          text: text,
          model: model || @model_id,
          usage: {
            "input_tokens" => resp.usage&.input_tokens,
            "output_tokens" => resp.usage&.output_tokens
          },
          raw_response: resp.to_h
        )
      end

      private

      def split_messages(messages)
        system_parts = []
        out = []
        messages.each do |m|
          h = (m.is_a?(Hash) ? m : m.to_h).transform_keys(&:to_s)
          case h["role"]
          when "system"
            system_parts << h["content"].to_s
          when "user", "assistant"
            out << { role: h["role"], content: h["content"].to_s }
          end
        end
        [system_parts.join("\n\n"), out]
      end

      def normalize_role(r)
        r.to_s == "assistant" ? "assistant" : "user"
      end

      def extract_text(resp)
        resp.output&.message&.content&.each do |block|
          return block.text if block.respond_to?(:text) && block.text
        end
        nil
      end
    end
  end
end
