# frozen_string_literal: true

module AiScreenAssistant
  # Optional bag of identifiers for {Credentials::Resolver} implementations.
  CredentialContext = Struct.new(:tenant_id, :user_id, :session_id, :metadata, keyword_init: true) do
    def initialize(**kwargs)
      super(**{ metadata: {} }.merge(kwargs))
    end
  end
end
