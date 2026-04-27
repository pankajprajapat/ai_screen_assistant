# frozen_string_literal: true

module AiScreenAssistant
  module TopicGuard
    class HostVeto
      def initialize(callback = nil)
        @callback = callback
      end

      def evaluate(reply:, user_message:, screen_context:, thread_id:, store:)
        return Decision.allow(reply) if @callback.nil?

        ctx = {
          reply: reply,
          user_message: user_message,
          screen_context: screen_context,
          thread_id: thread_id,
          store: store
        }
        case @callback.call(ctx)
        when :ok, true, nil
          Decision.allow(reply)
        when :block, false
          Decision.block(
            "I can only help with what is on this screen. Please ask about the information shown here.",
            reason: "host_veto"
          )
        else
          Decision.allow(reply)
        end
      end
    end
  end
end
