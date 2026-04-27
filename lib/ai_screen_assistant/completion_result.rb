# frozen_string_literal: true

module AiScreenAssistant
  class CompletionResult
    attr_reader :text, :model, :usage, :raw_response

    def initialize(text:, model: nil, usage: nil, raw_response: nil)
      @text = text
      @model = model
      @usage = usage || {}
      @raw_response = raw_response
    end
  end
end
