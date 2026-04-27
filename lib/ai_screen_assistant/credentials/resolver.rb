# frozen_string_literal: true

module AiScreenAssistant
  module Credentials
    class Resolver
      # @param credential_context [AiScreenAssistant::CredentialContext, nil]
      # @return [Hash] provider-specific credentials (e.g. { api_key: "..." })
      def resolve(credential_context = nil)
        raise NotImplementedError
      end
    end
  end
end
