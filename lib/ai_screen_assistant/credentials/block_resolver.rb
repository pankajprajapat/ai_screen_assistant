# frozen_string_literal: true

module AiScreenAssistant
  module Credentials
    class BlockResolver < Resolver
      def initialize(&block)
        raise ArgumentError, "block required" unless block
        @block = block
      end

      def resolve(credential_context = nil)
        ctx = credential_context || CredentialContext.new
        result = @block.call(ctx)
        raise ConfigurationError, "resolver block must return a Hash" unless result.is_a?(Hash)
        result.transform_keys(&:to_sym)
      end
    end
  end
end
