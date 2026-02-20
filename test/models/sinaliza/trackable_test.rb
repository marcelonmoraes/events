require "test_helper"

module Sinaliza
  class TrackableTest < ActiveSupport::TestCase
    test "user has events_as_actor association" do
      user = User.create!(name: "Alice")
      Event.create!(name: "login", actor: user)

      assert_equal 1, user.events_as_actor.count
      assert_equal "login", user.events_as_actor.first.name
    end

    test "user has events_as_target association" do
      user = User.create!(name: "Alice")
      Event.create!(name: "user.mentioned", target: user)

      assert_equal 1, user.events_as_target.count
    end

    test "track_event records event with self as actor" do
      user = User.create!(name: "Alice")

      assert_difference "Event.count", 1 do
        user.track_event("user.action", metadata: { action: "click" })
      end

      event = Event.last
      assert_equal "user.action", event.name
      assert_equal user, event.actor
      assert_equal "model", event.source
      assert_equal({ "action" => "click" }, event.metadata)
    end

    test "track_event with target" do
      user = User.create!(name: "Alice")
      post = Post.create!(title: "Hello")

      user.track_event("post.liked", target: post)

      event = Event.last
      assert_equal user, event.actor
      assert_equal post, event.target
    end

    test "track_event_as_target records event with self as target" do
      user = User.create!(name: "Alice")
      admin = User.create!(name: "Admin")

      user.track_event_as_target("user.banned", actor: admin)

      event = Event.last
      assert_equal admin, event.actor
      assert_equal user, event.target
      assert_equal "model", event.source
    end

    test "nullifies events when actor is destroyed" do
      user = User.create!(name: "Alice")
      Event.create!(name: "login", actor: user)

      user.destroy!

      event = Event.last
      assert_nil event.actor_id
      assert_nil event.actor_type
    end

    test "nullifies events when target is destroyed" do
      user = User.create!(name: "Alice")
      Event.create!(name: "mention", target: user)

      user.destroy!

      event = Event.last
      assert_nil event.target_id
      assert_nil event.target_type
    end
  end
end
