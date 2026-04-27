# frozen_string_literal: true

module AiScreenAssistant
  class Provider
    def complete(messages:, credentials:, tools: nil, **kwargs)
      raise NotImplementedError
    end
  end
end
