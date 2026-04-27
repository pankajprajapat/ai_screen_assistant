# frozen_string_literal: true

module AiScreenAssistant
  module TopicGuard
    # Heuristic: if `allowed_intent_tags` is non-empty, require at least one tag substring
    # or token overlap with the screen corpus; otherwise pass through.
    class KeywordOverlap
      def initialize(min_token_hits: 1)
        @min_token_hits = min_token_hits
      end

      def evaluate(reply:, user_message:, screen_context:, thread_id:, store:)
        tags = screen_context.allowed_intent_tags
        return Decision.allow(reply) if tags.empty?

        u = user_message.downcase
        return Decision.allow(reply) if tags.any? { |t| u.include?(t.downcase) }

        corpus_tokens = tokenize(corpus_for(screen_context))
        user_tokens = tokenize(user_message)
        hits = user_tokens.count { |w| corpus_tokens.include?(w) }
        if hits >= @min_token_hits
          Decision.allow(reply)
        else
          Decision.block(
            "I can only answer questions related to this screen. Try rephrasing using terms shown on the page.",
            reason: "keyword_overlap"
          )
        end
      end

      private

      def corpus_for(screen)
        [screen.human_summary, screen.route, screen.structured_payload.to_s, screen.recent_api_traces.join(" ")].compact.join(" ")
      end

      def tokenize(text)
        text.to_s.downcase.scan(/[a-z0-9_]{3,}/).uniq
      end
    end
  end
end
