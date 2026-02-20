require "test_helper"

module Sinaliza
  class EventsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
      5.times { |i| Event.create!(name: "event.#{i}", source: "test") }
    end

    test "index returns success" do
      get events_url
      assert_response :success
    end

    test "index lists events" do
      get events_url
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 5
    end

    test "index filters by name" do
      get events_url(name: "event.0")
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 1
    end

    test "index filters by source" do
      Event.create!(name: "other", source: "manual")
      get events_url(source: "test")
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 5
    end

    test "index filters by search query" do
      get events_url(q: "event.1")
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 1
    end

    test "index filters by context_type" do
      user = User.create!(name: "Alice")
      Event.create!(name: "a", context: user, source: "test")
      Event.create!(name: "b", source: "test")

      get events_url(context_type: "User")
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 1
    end

    test "show displays context" do
      user = User.create!(name: "Alice")
      event = Event.create!(name: "test.context", context: user)

      get event_url(event)
      assert_response :success
      assert_select "th", "Context"
    end

    test "index cursor pagination" do
      events = 55.times.map { |i| Event.create!(name: "paginated.#{i}") }

      get events_url
      assert_response :success
      assert_select "a", text: "Older events"

      last_event = Event.reverse_chronological.offset(49).first
      get events_url(before_id: last_event.id)
      assert_response :success
    end

    test "show returns success" do
      event = Event.first
      get event_url(event)
      assert_response :success
      assert_select "h1", "Event ##{event.id}"
    end

    test "show displays event details" do
      user = User.create!(name: "Alice")
      event = Event.create!(
        name: "test.detail",
        actor: user,
        metadata: { key: "value" },
        ip_address: "1.2.3.4"
      )

      get event_url(event)
      assert_response :success
      assert_select "span.sinaliza-badge", "test.detail"
    end

    test "index shows only root events" do
      parent = Event.create!(name: "order.completed", source: "test")
      Event.create!(name: "payment.processed", parent: parent, source: "test")

      get events_url
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 6 # 5 from setup + 1 parent
    end

    test "index shows children count" do
      parent = Event.create!(name: "order.completed", source: "test")
      Event.create!(name: "payment.processed", parent: parent, source: "test")
      Event.create!(name: "stock.reserved", parent: parent, source: "test")

      get events_url
      assert_response :success
      assert_select "th", "Children"
    end

    test "show displays children table" do
      parent = Event.create!(name: "order.completed")
      Event.create!(name: "payment.processed", parent: parent)
      Event.create!(name: "stock.reserved", parent: parent)

      get event_url(parent)
      assert_response :success
      assert_select "h2", "Sub-events"
      assert_select "table.sinaliza-table tbody tr", 2
    end

    test "show displays parent link for child event" do
      parent = Event.create!(name: "order.completed")
      child = Event.create!(name: "payment.processed", parent: parent)

      get event_url(child)
      assert_response :success
      assert_select "a.sinaliza-link", "Event ##{parent.id}"
    end

    private

    def events_url(params = {})
      sinaliza.events_url(params)
    end

    def event_url(event)
      sinaliza.event_url(event)
    end
  end
end
