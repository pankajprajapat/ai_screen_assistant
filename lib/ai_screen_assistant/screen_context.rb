# frozen_string_literal: true

require "json"

module AiScreenAssistant
  # Host-supplied snapshot of the current UI and related API data (redacted by the host before sending).
  class ScreenContext
    attr_reader :screen_id, :route, :human_summary, :structured_payload, :recent_api_traces,
                :allowed_intent_tags, :captured_at

    def initialize(
      screen_id:,
      route: nil,
      human_summary: nil,
      structured_payload: {},
      recent_api_traces: [],
      allowed_intent_tags: [],
      captured_at: Time.now.utc
    )
      @screen_id = screen_id.to_s
      @route = route&.to_s
      @human_summary = human_summary&.to_s
      @structured_payload = deep_stringify(structured_payload || {})
      @recent_api_traces = Array(recent_api_traces).map(&:to_s)
      @allowed_intent_tags = Array(allowed_intent_tags).map(&:to_s)
      @captured_at = captured_at
      freeze
    end

    def to_prompt_fragment
      parts = []
      parts << "screen_id: #{screen_id}"
      parts << "route: #{route}" if route && !route.empty?
      parts << "summary: #{human_summary}" if human_summary && !human_summary.empty?
      parts << "structured: #{JSON.generate(structured_payload)}" if structured_payload.any?
      parts << "api_traces:\n#{recent_api_traces.join("\n---\n")}" if recent_api_traces.any?
      parts << "allowed_intent_tags: #{allowed_intent_tags.join(", ")}" if allowed_intent_tags.any?
      parts << "captured_at: #{captured_at.iso8601(6)}"
      parts.join("\n")
    end

    def as_json
      {
        "screen_id" => screen_id,
        "route" => route,
        "human_summary" => human_summary,
        "structured_payload" => structured_payload,
        "recent_api_traces" => recent_api_traces,
        "allowed_intent_tags" => allowed_intent_tags,
        "captured_at" => captured_at.iso8601(6)
      }
    end

    private

    def deep_stringify(obj)
      case obj
      when Hash then obj.transform_keys(&:to_s).transform_values { |v| deep_stringify(v) }
      when Array then obj.map { |v| deep_stringify(v) }
      else obj
      end
    end
  end
end
