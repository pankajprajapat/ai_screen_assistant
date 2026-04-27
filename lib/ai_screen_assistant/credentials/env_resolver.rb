# frozen_string_literal: true

module AiScreenAssistant
  module Credentials
    class EnvResolver < Resolver
      def initialize(env_key, organization_env_key: nil)
        @env_key = env_key.to_s
        @organization_env_key = organization_env_key&.to_s
      end

      def resolve(credential_context = nil)
        key = ENV.fetch(@env_key)
        out = { api_key: key }
        if @organization_env_key
          org = ENV[@organization_env_key]
          out[:organization_id] = org if org && !org.empty?
        end
        out
      rescue KeyError
        raise ConfigurationError, "missing environment variable #{@env_key}"
      end
    end
  end
end
