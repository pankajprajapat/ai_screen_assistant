# frozen_string_literal: true

require "test_helper"

class StubProviderTest < Minitest::Test
  def test_complete_echoes_user
    p = AiScreenAssistant::Providers::StubProvider.new(default_text: "ok")
    r = p.complete(messages: [{ role: "user", content: "hello" }], credentials: {})
    assert_includes r.text, "hello"
  end
end
