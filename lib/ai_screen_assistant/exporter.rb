# frozen_string_literal: true

require "json"

module AiScreenAssistant
  class Exporter
    # One JSON object per line (audit / backup).
    # Optional +redact+ receives each message hash (from {ChatMessage#to_h}) and returns the hash to serialize.
    def self.messages_to_jsonl(messages, &redact)
      messages.map do |m|
        h = m.to_h
        h = redact.call(h) if redact
        JSON.generate(h)
      end.join("\n") + (messages.empty? ? "" : "\n")
    end

    # OpenAI-style fine-tune example: one line per training row with a `messages` array.
    def self.thread_to_openai_finetune_line(messages)
      pairs = messages.select { |m| %w[user assistant].include?(m.role) }.map do |m|
        { "role" => m.role, "content" => m.content }
      end
      JSON.generate({ "messages" => pairs }) + "\n"
    end

    def self.append_openai_finetune_line(io, messages)
      io.write(thread_to_openai_finetune_line(messages))
    end
  end
end
