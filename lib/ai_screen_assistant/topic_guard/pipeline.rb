# frozen_string_literal: true

module AiScreenAssistant
  module TopicGuard
    class Pipeline
      def initialize(guards)
        @guards = Array(guards)
      end

      def evaluate(reply:, user_message:, screen_context:, thread_id:, store:)
        return Decision.allow(reply) if @guards.empty?

        current = reply
        @guards.each do |g|
          decision = g.evaluate(reply: current, user_message: user_message, screen_context: screen_context, thread_id: thread_id, store: store)
          current = decision.reply
          return decision unless decision.allowed
        end
        Decision.allow(current)
      end
    end
  end
end
