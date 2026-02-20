# Sinaliza

A Rails engine for recording and browsing application events. Track user actions, system events, and anything worth logging — from models, controllers, or anywhere in your code.

Events are stored in the database and viewable through a mountable monitor dashboard.

## Installation

Add to your Gemfile:

```ruby
gem "sinaliza", github: "marcelonmoraes/sinaliza"
```

Then run:

```bash
bundle install
bin/rails sinaliza:install:migrations
bin/rails db:migrate
```

Mount the engine in your `config/routes.rb`:

```ruby
mount Sinaliza::Engine => "/sinaliza"
```

## Usage

### Direct recording

```ruby
# Synchronous
Sinaliza.record(name: "user.signed_up", actor: user, metadata: { plan: "pro" })

# Asynchronous (via ActiveJob)
Sinaliza.record_later(name: "report.generated", target: report)
```

Both methods accept:

| Parameter    | Description                          | Default               |
|-------------|--------------------------------------|-----------------------|
| `name`      | Event name (required)                | —                     |
| `actor`     | Who performed the action (any model) | `nil`                 |
| `target`    | What was acted upon (any model)      | `nil`                 |
| `metadata`  | Arbitrary hash of extra data         | `{}`                  |
| `source`    | Origin label                         | `"manual"`            |
| `ip_address`| IP address                           | `nil`                 |
| `user_agent`| User agent string                    | `nil`                 |
| `request_id`| Request ID                           | `nil`                 |

### Model concern — `Sinaliza::Trackable`

Include in any model to get event associations and helper methods:

```ruby
class User < ApplicationRecord
  include Sinaliza::Trackable
end
```

This gives you:

```ruby
user.events_as_actor   # events where user is the actor
user.events_as_target  # events where user is the target

user.track_event("profile.updated", metadata: { field: "email" })
user.track_event("post.published", target: post)

post.track_event_as_target("post.featured", actor: admin)
```

Events are recorded with `source: "model"`. When an actor or target is destroyed, associated events are preserved with nullified references (`dependent: :nullify`).

### Controller concern — `Sinaliza::Traceable`

Include in any controller to track actions declaratively or manually:

```ruby
class OrdersController < ApplicationController
  include Sinaliza::Traceable

  # Declarative — runs as an after_action callback
  track_event "orders.listed", only: :index
  track_event "order.viewed", only: :show, metadata: -> { { order_id: params[:id] } }

  # Conditional tracking
  track_event "order.created", only: :create, if: -> { response.successful? }

  def refund
    order = Order.find(params[:id])
    order.refund!

    # Manual — call anywhere in an action
    record_event("order.refunded", target: order, metadata: { reason: params[:reason] })

    redirect_to order
  end
end
```

Events are recorded with `source: "controller"`. Request context (IP address, user agent, request ID) is captured automatically based on configuration.

The actor is resolved by calling the method defined in `Sinaliza.configuration.actor_method` (default: `current_user`).

### Query scopes

```ruby
Sinaliza::Event.by_name("user.login")
Sinaliza::Event.by_source("controller")
Sinaliza::Event.by_actor_type("User")
Sinaliza::Event.since(1.week.ago)
Sinaliza::Event.before(Date.yesterday)
Sinaliza::Event.between(1.week.ago, 1.day.ago)
Sinaliza::Event.search("login")
Sinaliza::Event.chronological          # oldest first
Sinaliza::Event.reverse_chronological  # newest first
```

Scopes are chainable:

```ruby
Sinaliza::Event.by_name("order.created").by_actor_type("User").since(1.day.ago)
```

## Dashboard

The engine mounts a monitor dashboard at your chosen path. It provides:

- Paginated event list (cursor-based, 50 per page)
- Filtering by name, source, actor type, date range, and free-text search
- Detail view for each event with formatted JSON metadata

### Protecting the dashboard

The gem does not include authentication. Protect access via route constraints in your host app:

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount Sinaliza::Engine => "/sinaliza"
end

# or with a simple constraint
mount Sinaliza::Engine => "/sinaliza", constraints: AdminConstraint.new
```

## Configuration

```ruby
# config/initializers/sinaliza.rb
Sinaliza.configure do |config|
  # Controller method used to resolve the actor (default: :current_user)
  config.actor_method = :current_user

  # Default source label for Sinaliza.record calls (default: "manual")
  config.default_source = "manual"

  # Capture IP, user agent, and request ID in controller events (default: true)
  config.record_request_info = true

  # Auto-purge events older than this duration (default: nil — no purging)
  config.purge_after = 90.days
end
```

## Purging old events

If `purge_after` is configured, run the rake task to delete old events:

```bash
bin/rails sinaliza:purge
```

Schedule it with cron, Heroku Scheduler, or whatever you prefer.

## Database schema

Events are stored in a single `sinaliza_events` table with polymorphic `actor` and `target` columns. The `metadata` column uses `json` type for cross-database compatibility (SQLite, PostgreSQL, MySQL).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
