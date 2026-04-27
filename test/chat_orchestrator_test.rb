# frozen_string_literal: true

require "test_helper"

class ChatOrchestratorTest < Minitest::Test
  def setup
    @store = AiScreenAssistant::Stores::MemoryStore.new
    @provider = AiScreenAssistant::Providers::StubProvider.new(default_text: "AI")
    @resolver = AiScreenAssistant::Credentials::StaticResolver.new(api_key: "x")
    @screen = AiScreenAssistant::ScreenContext.new(
      screen_id: "checkout",
      human_summary: "Checkout totals $42",
      allowed_intent_tags: %w[checkout total]
    )
  end

  def test_creates_thread_and_persists
    orch = AiScreenAssistant::ChatOrchestrator.new(
      provider: @provider,
      store: @store,
      credential_resolver: @resolver
    )
    r = orch.respond(thread_id: nil, user_message: "What is the total?", screen_context: @screen)
    refute_nil r.thread_id
    assert_equal 2, @store.messages(r.thread_id).size
  end

  def test_preflight_keyword_overlap_blocks
    pre = AiScreenAssistant::TopicGuard::Pipeline.new([AiScreenAssistant::TopicGuard::KeywordOverlap.new])
    orch = AiScreenAssistant::ChatOrchestrator.new(
      provider: @provider,
      store: @store,
      credential_resolver: @resolver,
      preflight: pre
    )
    r = orch.respond(thread_id: nil, user_message: "Tell me about Mars rovers", screen_context: @screen)
    assert r.blocked
    assert_includes r.reply, "only answer"
  end

  def test_json_envelope_postflight
    post = AiScreenAssistant::TopicGuard::Pipeline.new([
      AiScreenAssistant::TopicGuard::JSONEnvelope.new
    ])
    provider = Class.new(AiScreenAssistant::Provider) do
      def complete(messages:, credentials:, **)
        AiScreenAssistant::CompletionResult.new(text: '{"kind":"answer","body":"42"}', model: "stub")
      end
    end.new

    orch = AiScreenAssistant::ChatOrchestrator.new(
      provider: provider,
      store: @store,
      credential_resolver: @resolver,
      postflight: post
    )
    r = orch.respond(thread_id: nil, user_message: "total?", screen_context: @screen)
    assert_equal "42", r.reply
  end
end
