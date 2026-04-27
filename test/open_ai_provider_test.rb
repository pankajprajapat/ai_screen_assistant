# frozen_string_literal: true

require "test_helper"

class OpenAiProviderTest < Minitest::Test
  def test_success_parse
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          model: "gpt-4o-mini",
          choices: [{ message: { role: "assistant", content: "hi" } }],
          usage: { "total_tokens" => 3 }
        }.to_json
      )

    p = AiScreenAssistant::Providers::OpenAiProvider.new
    r = p.complete(
      messages: [{ role: "user", content: "hello" }],
      credentials: { api_key: "sk-test" }
    )
    assert_equal "hi", r.text
  end

  def test_missing_key
    p = AiScreenAssistant::Providers::OpenAiProvider.new
    assert_raises(AiScreenAssistant::ConfigurationError) do
      p.complete(messages: [{ role: "user", content: "x" }], credentials: {})
    end
  end
end
