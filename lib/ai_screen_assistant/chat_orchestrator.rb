# frozen_string_literal: true

module AiScreenAssistant
  class ChatOrchestrator
    attr_reader :provider, :store, :credential_resolver, :preflight, :postflight, :json_reply

    def initialize(
      provider:,
      store:,
      credential_resolver:,
      preflight: TopicGuard::Pipeline.new([]),
      postflight: TopicGuard::Pipeline.new([TopicGuard::HostVeto.new]),
      json_reply: false
    )
      @provider = provider
      @store = store
      @credential_resolver = credential_resolver
      @preflight = preflight
      @postflight = postflight
      @json_reply = json_reply
    end

    # @param thread_id [String, nil] existing thread or nil to create
    # @param user_message [String]
    # @param screen_context [ScreenContext]
    # @param credential_context [CredentialContext, nil]
    # @param thread_metadata [Hash] merged when creating a new thread
    def respond(thread_id:, user_message:, screen_context:, credential_context: nil, thread_metadata: {})
      ctx = credential_context || CredentialContext.new
      tid = thread_id || store.create_thread(metadata: thread_metadata.merge("screen_id" => screen_context.screen_id))

      store.update_thread_metadata(tid, { "last_screen_id" => screen_context.screen_id, "last_screen_json" => screen_context.as_json })

      store.append_message(tid, "user", user_message.to_s, metadata: { "screen_context" => screen_context.as_json })

      pre_decision = preflight.evaluate(
        reply: "",
        user_message: user_message.to_s,
        screen_context: screen_context,
        thread_id: tid,
        store: store
      )
      unless pre_decision.allowed
        store.append_message(tid, "assistant", pre_decision.reply, metadata: { "guard" => pre_decision.reason, "preflight" => true })
        return RespondResult.new(thread_id: tid, reply: pre_decision.reply, guard_decision: pre_decision, blocked: true)
      end

      creds = credential_resolver.resolve(ctx)
      api_messages = build_api_messages(screen_context, store.messages(tid))

      completion = provider.complete(messages: api_messages, credentials: creds)

      post_decision = postflight.evaluate(
        reply: completion.text,
        user_message: user_message.to_s,
        screen_context: screen_context,
        thread_id: tid,
        store: store
      )

      store.append_message(
        tid,
        "assistant",
        post_decision.reply,
        metadata: {
          "model" => completion.model,
          "usage" => completion.usage,
          "guard" => post_decision.reason,
          "allowed" => post_decision.allowed
        }.compact
      )

      RespondResult.new(
        thread_id: tid,
        reply: post_decision.reply,
        completion: completion,
        guard_decision: post_decision,
        blocked: !post_decision.allowed
      )
    end

    private

    def build_api_messages(screen_context, history_messages)
      system = build_system_prompt(screen_context)
      pairs = history_messages.select { |m| %w[user assistant].include?(m.role) }.map { |m| { role: m.role, content: m.content } }
      [{ role: "system", content: system }] + pairs
    end

    def build_system_prompt(screen)
      base = <<~PROMPT
        You are an in-app assistant. You may ONLY answer using the screen context below.
        If the user asks for anything not grounded in this context (including unrelated code, trivia, or other screens), refuse briefly and ask them to stay on-topic.

        Screen context:
        ---
        #{screen.to_prompt_fragment}
        ---
      PROMPT

      if json_reply
        base + <<~PROMPT

          Respond with a single JSON object only, on one line, no markdown:
          {"kind":"answer","body":"<your answer>"} OR {"kind":"refusal","reason":"<short reason>"}
        PROMPT
      else
        base
      end
    end
  end
end
