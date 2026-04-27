# frozen_string_literal: true

module AiScreenAssistant
  class ConversationStore
    def create_thread(metadata: {})
      raise NotImplementedError
    end

    def append_message(thread_id, role, content, metadata: {})
      raise NotImplementedError
    end

    def messages(thread_id)
      raise NotImplementedError
    end

    def thread_metadata(thread_id)
      raise NotImplementedError
    end

    def update_thread_metadata(thread_id, metadata)
      raise NotImplementedError
    end

    def export_thread_jsonl(thread_id)
      raise NotImplementedError
    end
  end
end
