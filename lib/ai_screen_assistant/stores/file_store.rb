# frozen_string_literal: true

require "fileutils"
require "json"
require "securerandom"

module AiScreenAssistant
  module Stores
    class FileStore < ConversationStore
      def initialize(root_dir)
        @root = File.expand_path(root_dir)
        FileUtils.mkdir_p(File.join(@root, "threads"))
      end

      def create_thread(metadata: {})
        id = SecureRandom.uuid
        write_thread(id, { "messages" => [], "metadata" => stringify(metadata.merge(created_at: Time.now.utc.iso8601(6))) })
        id
      end

      def append_message(thread_id, role, content, metadata: {})
        data = read_thread(thread_id)
        msg = ChatMessage.new(role: role, content: content, metadata: metadata)
        data["messages"] << message_to_h(msg)
        write_thread(thread_id, data)
        msg
      end

      def messages(thread_id)
        read_thread(thread_id)["messages"].map { |h| hash_to_message(h) }
      end

      def thread_metadata(thread_id)
        read_thread(thread_id)["metadata"] || {}
      end

      def update_thread_metadata(thread_id, metadata)
        data = read_thread(thread_id)
        data["metadata"] = stringify(thread_metadata(thread_id).merge(stringify(metadata)))
        write_thread(thread_id, data)
      end

      def export_thread_jsonl(thread_id)
        Exporter.messages_to_jsonl(messages(thread_id))
      end

      private

      def path_for(id)
        File.join(@root, "threads", "#{id}.json")
      end

      def read_thread(thread_id)
        p = path_for(thread_id)
        raise ArgumentError, "unknown thread #{thread_id}" unless File.exist?(p)

        JSON.parse(File.read(p))
      end

      def write_thread(thread_id, data)
        File.write(path_for(thread_id), JSON.pretty_generate(data))
      end

      def message_to_h(msg)
        {
          "role" => msg.role,
          "content" => msg.content,
          "metadata" => stringify(msg.metadata),
          "created_at" => msg.created_at.iso8601(6)
        }
      end

      def hash_to_message(h)
        ChatMessage.new(
          role: h["role"],
          content: h["content"],
          metadata: h["metadata"] || {},
          created_at: Time.parse(h["created_at"] || h[:created_at] || Time.now.utc.iso8601(6))
        )
      end

      def stringify(obj)
        case obj
        when Hash then obj.transform_keys(&:to_s).transform_values { |v| stringify(v) }
        when Array then obj.map { |v| stringify(v) }
        else obj
        end
      end
    end
  end
end
