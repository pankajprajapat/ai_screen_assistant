# frozen_string_literal: true

module AiScreenAssistant
  module Credentials
    class StaticResolver < Resolver
      def initialize(credentials)
        @credentials = {}
        credentials.each { |k, v| @credentials[k.to_sym] = v }
        @credentials.freeze
      end

      def resolve(credential_context = nil)
        @credentials.dup
      end
    end
  end
end
