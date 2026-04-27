# frozen_string_literal: true

require "json"

module AiScreenAssistant
  module TopicGuard
    # When the model returns only JSON: {"kind":"answer","body":"..."} or {"kind":"refusal","reason":"..."}
    class JSONEnvelope
      def evaluate(reply:, user_message:, screen_context:, thread_id:, store:)
        stripped = reply.strip
        data = JSON.parse(stripped)
        kind = data["kind"] || data[:kind]
        case kind.to_s
        when "answer"
          body = data["body"] || data[:body]
          body = body.to_s
          body.empty? ? Decision.block("Empty answer.", reason: "json_envelope") : Decision.allow(body)
        when "refusal"
          reason = data["reason"] || data[:reason] || "refused"
          Decision.block(reason.to_s, reason: "model_refusal")
        else
          Decision.block(
            "I can only help with what is on this screen.",
            reason: "json_envelope_invalid"
          )
        end
      rescue JSON::ParserError
        Decision.block(
          "I can only help with what is on this screen.",
          reason: "json_envelope_parse"
        )
      end
    end
  end
end
