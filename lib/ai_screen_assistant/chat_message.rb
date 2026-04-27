# frozen_string_literal: true

module AiScreenAssistant
  class ChatMessage
    ROLES = %w[system user assistant].freeze

    attr_reader :role, :content, :metadata, :created_at

    def initialize(role:, content:, metadata: {}, created_at: Time.now.utc)
      @role = role.to_s
      @content = content.to_s
      @metadata = metadata.freeze
      @created_at = created_at
      raise ArgumentError, "invalid role: #{@role}" unless ROLES.include?(@role)
    end

    def to_h
      { "role" => role, "content" => content, "metadata" => metadata, "created_at" => created_at.iso8601(6) }
    end
  end
end
