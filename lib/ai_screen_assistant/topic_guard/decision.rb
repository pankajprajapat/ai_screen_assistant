# frozen_string_literal: true

module AiScreenAssistant
  module TopicGuard
    class Decision
      attr_reader :allowed, :reply, :reason

      def initialize(allowed:, reply:, reason: nil)
        @allowed = allowed
        @reply = reply
        @reason = reason
      end

      def self.allow(reply)
        new(allowed: true, reply: reply)
      end

      def self.block(reply, reason: nil)
        new(allowed: false, reply: reply, reason: reason)
      end
    end
  end
end
