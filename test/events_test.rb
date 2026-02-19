require "test_helper"

class EventsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "it has a version number" do
    assert Events::VERSION
  end

  test "Events.record creates an event" do
    event = Events.record(name: "test.event")

    assert_equal "test.event", event.name
    assert_equal "manual", event.source
  end

  test "Events.record with all attributes" do
    user = User.create!(name: "Alice")
    post = Post.create!(title: "Hello")

    event = Events.record(
      name: "post.viewed",
      actor: user,
      target: post,
      metadata: { page: 1 },
      source: "api",
      ip_address: "127.0.0.1",
      user_agent: "TestAgent",
      request_id: "req-123"
    )

    assert_equal "post.viewed", event.name
    assert_equal user, event.actor
    assert_equal post, event.target
    assert_equal({ "page" => 1 }, event.metadata)
    assert_equal "api", event.source
    assert_equal "127.0.0.1", event.ip_address
    assert_equal "TestAgent", event.user_agent
    assert_equal "req-123", event.request_id
  end

  test "Events.record uses default_source from configuration" do
    original = Events.configuration.default_source
    Events.configuration.default_source = "api"

    event = Events.record(name: "test")
    assert_equal "api", event.source
  ensure
    Events.configuration.default_source = original
  end

  test "Events.record_later enqueues a job" do
    assert_enqueued_with(job: Events::RecordEventJob) do
      Events.record_later(name: "async.event")
    end
  end

  test "Events.record_later with actor serializes as GlobalID" do
    user = User.create!(name: "Alice")

    assert_enqueued_with(job: Events::RecordEventJob) do
      Events.record_later(name: "async.event", actor: user)
    end
  end

  test "Events.configure yields configuration" do
    Events.configure do |config|
      config.actor_method = :authenticated_user
    end

    assert_equal :authenticated_user, Events.configuration.actor_method
  ensure
    Events.configuration.actor_method = :current_user
  end

  test "configuration has sensible defaults" do
    config = Events::Configuration.new

    assert_equal :current_user, config.actor_method
    assert_equal "manual", config.default_source
    assert_equal true, config.record_request_info
    assert_nil config.purge_after
  end

  test "Events.record with parent event" do
    parent = Events.record(name: "order.completed")
    child = Events.record(name: "payment.processed", parent: parent)

    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "Events.record with parent_id" do
    parent = Events.record(name: "order.completed")
    child = Events.record(name: "payment.processed", parent: parent.id)

    assert_equal parent, child.parent
  end

  test "Events.record_later with parent enqueues job with parent_id" do
    parent = Events.record(name: "order.completed")

    assert_enqueued_with(job: Events::RecordEventJob) do
      Events.record_later(name: "payment.processed", parent: parent)
    end
  end
end
