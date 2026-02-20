require "test_helper"

class Sinaliza::TraceableTest < ActionDispatch::IntegrationTest
  test "track_event callback records event on index" do
    assert_difference "Sinaliza::Event.count", 1 do
      get "/tracked"
    end

    event = Sinaliza::Event.last
    assert_equal "page.viewed", event.name
    assert_equal "controller", event.source
    assert_not_nil event.ip_address
    assert_not_nil event.request_id
  end

  test "track_event callback records event on show with dynamic metadata" do
    assert_difference "Sinaliza::Event.count", 1 do
      get "/tracked/42"
    end

    event = Sinaliza::Event.last
    assert_equal "item.shown", event.name
    assert_equal "42", event.metadata["id"]
  end

  test "record_event manually records event with request context" do
    assert_difference "Sinaliza::Event.count", 1 do
      post "/tracked"
    end

    event = Sinaliza::Event.last
    assert_equal "item.created", event.name
    assert_equal "controller", event.source
    assert_equal({ "custom" => true }, event.metadata)
  end

  test "resolves actor from current_user" do
    user = User.create!(name: "Alice")

    get "/tracked", headers: { "X-User-Id" => user.id.to_s }

    event = Sinaliza::Event.last
    assert_equal user, event.actor
  end

  test "records nil actor when current_user is nil" do
    get "/tracked"

    event = Sinaliza::Event.last
    assert_nil event.actor
  end

  test "skips request info when configured to not record" do
    original = Sinaliza.configuration.record_request_info
    Sinaliza.configuration.record_request_info = false

    get "/tracked"

    event = Sinaliza::Event.last
    assert_nil event.ip_address
    assert_nil event.user_agent
    assert_nil event.request_id
  ensure
    Sinaliza.configuration.record_request_info = original
  end
end
