# frozen_string_literal: true

module AiScreenAssistant
  class RespondResult
    attr_reader :thread_id, :reply, :completion, :guard_decision, :blocked

    def initialize(thread_id:, reply:, completion: nil, guard_decision: nil, blocked: false)
      @thread_id = thread_id
      @reply = reply
      @completion = completion
      @guard_decision = guard_decision
      @blocked = blocked
    end
  end
end
