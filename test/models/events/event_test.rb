require "test_helper"

module Events
  class EventTest < ActiveSupport::TestCase
    test "requires name" do
      event = Event.new(name: nil)
      assert_not event.valid?
      assert_includes event.errors[:name], "can't be blank"
    end

    test "creates event with name only" do
      event = Event.create!(name: "test.event")
      assert_equal "test.event", event.name
      assert_equal "manual", event.source
      assert_equal({}, event.metadata)
    end

    test "polymorphic actor association" do
      user = User.create!(name: "Alice")
      event = Event.create!(name: "login", actor: user)

      assert_equal "User", event.actor_type
      assert_equal user.id, event.actor_id
      assert_equal user, event.actor
    end

    test "polymorphic target association" do
      post = Post.create!(title: "Hello")
      event = Event.create!(name: "post.viewed", target: post)

      assert_equal "Post", event.target_type
      assert_equal post.id, event.target_id
      assert_equal post, event.target
    end

    test "by_name scope" do
      Event.create!(name: "login")
      Event.create!(name: "logout")

      assert_equal 1, Event.by_name("login").count
    end

    test "by_source scope" do
      Event.create!(name: "a", source: "controller")
      Event.create!(name: "b", source: "model")

      assert_equal 1, Event.by_source("controller").count
    end

    test "by_actor_type scope" do
      user = User.create!(name: "Alice")
      Event.create!(name: "a", actor: user)
      Event.create!(name: "b")

      assert_equal 1, Event.by_actor_type("User").count
    end

    test "since scope" do
      old = Event.create!(name: "old", created_at: 3.days.ago)
      recent = Event.create!(name: "recent", created_at: 1.hour.ago)

      results = Event.since(1.day.ago)
      assert_includes results, recent
      assert_not_includes results, old
    end

    test "before scope" do
      old = Event.create!(name: "old", created_at: 3.days.ago)
      recent = Event.create!(name: "recent", created_at: 1.hour.ago)

      results = Event.before(1.day.ago)
      assert_includes results, old
      assert_not_includes results, recent
    end

    test "between scope" do
      old = Event.create!(name: "old", created_at: 10.days.ago)
      mid = Event.create!(name: "mid", created_at: 3.days.ago)
      recent = Event.create!(name: "recent", created_at: 1.hour.ago)

      results = Event.between(5.days.ago, 1.day.ago)
      assert_includes results, mid
      assert_not_includes results, old
      assert_not_includes results, recent
    end

    test "chronological scope" do
      second = Event.create!(name: "second", created_at: 1.hour.ago)
      first = Event.create!(name: "first", created_at: 2.hours.ago)

      assert_equal [ first, second ], Event.chronological.to_a
    end

    test "search scope" do
      Event.create!(name: "user.login", source: "controller")
      Event.create!(name: "post.created", source: "model")

      assert_equal 1, Event.search("login").count
      assert_equal 1, Event.search("model").count
    end

    test "metadata stores hash" do
      event = Event.create!(name: "test", metadata: { key: "value", nested: { a: 1 } })
      event.reload

      assert_equal "value", event.metadata["key"]
      assert_equal 1, event.metadata["nested"]["a"]
    end
  end
end
