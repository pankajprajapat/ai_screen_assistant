# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minitest/autorun"
require "webmock/minitest"

require "ai_screen_assistant"

WebMock.disable_net_connect!(allow_localhost: true)
