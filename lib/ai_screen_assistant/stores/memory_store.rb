# frozen_string_literal: true

require "securerandom"

module AiScreenAssistant
  module Stores
    class MemoryStore < ConversationStore
      def initialize
        @threads = {}
      end

      def create_thread(metadata: {})
        id = SecureRandom.uuid
        @threads[id] = { messages: [], metadata: metadata.merge("created_at" => Time.now.utc.iso8601(6)) }
        id
      end

      def append_message(thread_id, role, content, metadata: {})
        raise ArgumentError, "unknown thread #{thread_id}" unless @threads[thread_id]

        msg = ChatMessage.new(role: role, content: content, metadata: metadata)
        @threads[thread_id][:messages] << msg
        msg
      end

      def messages(thread_id)
        (@threads[thread_id]&.fetch(:messages)) || []
      end

      def thread_metadata(thread_id)
        (@threads[thread_id]&.fetch(:metadata)) || {}
      end

      def update_thread_metadata(thread_id, metadata)
        raise ArgumentError, "unknown thread #{thread_id}" unless @threads[thread_id]

        @threads[thread_id][:metadata] = thread_metadata(thread_id).merge(stringify_keys(metadata))
      end

      def export_thread_jsonl(thread_id)
        Exporter.messages_to_jsonl(messages(thread_id))
      end

      private

      def stringify_keys(h)
        h.to_h.transform_keys(&:to_s)
      end
    end
  end
end
