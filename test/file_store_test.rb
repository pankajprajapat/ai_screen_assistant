# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FileStoreTest < Minitest::Test
  def test_roundtrip
    Dir.mktmpdir do |dir|
      store = AiScreenAssistant::Stores::FileStore.new(dir)
      tid = store.create_thread(metadata: { "a" => 1 })
      store.append_message(tid, "user", "hi")
      store.append_message(tid, "assistant", "yo")
      store2 = AiScreenAssistant::Stores::FileStore.new(dir)
      assert_equal 2, store2.messages(tid).size
      assert_equal "yo", store2.messages(tid).last.content
    end
  end
end
