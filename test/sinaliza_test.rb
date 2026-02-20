require "test_helper"

class SinalizaTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "it has a version number" do
    assert Sinaliza::VERSION
  end

  test "Sinaliza.record creates an event" do
    event = Sinaliza.record(name: "test.event")

    assert_equal "test.event", event.name
    assert_equal "manual", event.source
  end

  test "Sinaliza.record with all attributes" do
    user = User.create!(name: "Alice")
    post = Post.create!(title: "Hello")

    event = Sinaliza.record(
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

  test "Sinaliza.record uses default_source from configuration" do
    original = Sinaliza.configuration.default_source
    Sinaliza.configuration.default_source = "api"

    event = Sinaliza.record(name: "test")
    assert_equal "api", event.source
  ensure
    Sinaliza.configuration.default_source = original
  end

  test "Sinaliza.record_later enqueues a job" do
    assert_enqueued_with(job: Sinaliza::RecordEventJob) do
      Sinaliza.record_later(name: "async.event")
    end
  end

  test "Sinaliza.record_later with actor serializes as GlobalID" do
    user = User.create!(name: "Alice")

    assert_enqueued_with(job: Sinaliza::RecordEventJob) do
      Sinaliza.record_later(name: "async.event", actor: user)
    end
  end

  test "Sinaliza.configure yields configuration" do
    Sinaliza.configure do |config|
      config.actor_method = :authenticated_user
    end

    assert_equal :authenticated_user, Sinaliza.configuration.actor_method
  ensure
    Sinaliza.configuration.actor_method = :current_user
  end

  test "configuration has sensible defaults" do
    config = Sinaliza::Configuration.new

    assert_equal :current_user, config.actor_method
    assert_equal "manual", config.default_source
    assert_equal true, config.record_request_info
    assert_nil config.purge_after
  end

  test "Sinaliza.record with context" do
    user = User.create!(name: "Alice")
    post = Post.create!(title: "Hello")

    event = Sinaliza.record(
      name: "post.viewed",
      actor: user,
      target: post,
      context: user,
      metadata: { page: 1 }
    )

    assert_equal user, event.actor
    assert_equal post, event.target
    assert_equal user, event.context
  end

  test "Sinaliza.record_later with context serializes as GlobalID" do
    user = User.create!(name: "Alice")

    assert_enqueued_with(job: Sinaliza::RecordEventJob) do
      Sinaliza.record_later(name: "async.event", context: user)
    end
  end

  test "Sinaliza.record with parent event" do
    parent = Sinaliza.record(name: "order.completed")
    child = Sinaliza.record(name: "payment.processed", parent: parent)

    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "Sinaliza.record with parent_id" do
    parent = Sinaliza.record(name: "order.completed")
    child = Sinaliza.record(name: "payment.processed", parent: parent.id)

    assert_equal parent, child.parent
  end

  test "Sinaliza.record_later with parent enqueues job with parent_id" do
    parent = Sinaliza.record(name: "order.completed")

    assert_enqueued_with(job: Sinaliza::RecordEventJob) do
      Sinaliza.record_later(name: "payment.processed", parent: parent)
    end
  end
end
