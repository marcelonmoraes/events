---
layout: default
title: Home
---

# Sinaliza

A Rails engine for recording and browsing application events. Track user actions, system events, and anything worth logging — from models, controllers, or anywhere in your code.

Events are stored in the database and viewable through a mountable monitor dashboard.

[View on GitHub](https://github.com/marcelonmoraes/sinaliza){: .btn }
[RubyGems](https://rubygems.org/gems/sinaliza){: .btn }

---

## Quick Start

Add to your Gemfile:

```ruby
gem "sinaliza"
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

---

## Recording Events

### From anywhere in your code

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
| `context`   | Business context for grouping (any model) | `nil`            |
| `parent`    | Parent event (for hierarchies)       | `nil`                 |

### From models — `Sinaliza::Trackable`

Include in any model to get event associations and helper methods:

```ruby
class User < ApplicationRecord
  include Sinaliza::Trackable
end
```

```ruby
user.events_as_actor    # events where user is the actor
user.events_as_target   # events where user is the target
user.events_as_context  # events where user is the context

user.track_event("profile.updated", metadata: { field: "email" })
user.track_event("post.published", target: post, context: subscription)

post.track_event_as_target("post.featured", actor: admin)

subscription.track_event_as_context("plan.upgraded", actor: user)
```

### From controllers — `Sinaliza::Traceable`

Track actions declaratively or manually:

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

---

## Event Context

The `context` parameter is a polymorphic association that lets you group events under a business object — such as a subscription, an order, or a project.

```ruby
subscription = user.subscriptions.current

Sinaliza.record(name: "plan.upgraded", actor: user, context: subscription,
                metadata: { from: "basic", to: "pro" })
Sinaliza.record(name: "payment.processed", actor: user, context: subscription)
Sinaliza.record(name: "invoice.sent", target: user, context: subscription)

# Query events by context
subscription.events_as_context
Sinaliza::Event.by_context(subscription)
Sinaliza::Event.by_context_type("Subscription")
```

---

## Parent & Children Events

Events support a parent/children hierarchy for representing causal chains or grouping sub-steps under a main event.

```ruby
signup = Sinaliza.record(name: "user.signed_up", actor: user)

Sinaliza.record(name: "welcome_email.sent", actor: user, parent: signup)
Sinaliza.record(name: "default_settings.created", actor: user, parent: signup)

signup.children
signup.root?                         # => true
signup.children.first.child?         # => true
signup.children.first.parent         # => the signup event

Sinaliza::Event.roots  # only top-level events
```

---

## Query Scopes

```ruby
Sinaliza::Event.by_name("user.login")
Sinaliza::Event.by_source("controller")
Sinaliza::Event.by_actor_type("User")
Sinaliza::Event.by_context(subscription)
Sinaliza::Event.by_context_type("Subscription")
Sinaliza::Event.roots
Sinaliza::Event.since(1.week.ago)
Sinaliza::Event.before(Date.yesterday)
Sinaliza::Event.between(1.week.ago, 1.day.ago)
Sinaliza::Event.search("login")
Sinaliza::Event.chronological
Sinaliza::Event.reverse_chronological
```

Scopes are chainable:

```ruby
Sinaliza::Event.by_name("order.created").by_actor_type("User").since(1.day.ago)
Sinaliza::Event.by_context(subscription).roots.reverse_chronological
```

---

## Dashboard

The engine mounts a monitor dashboard at your chosen path with:

- Paginated event list (cursor-based, 50 per page)
- Filtering by name, source, actor type, date range, and free-text search
- Detail view for each event with formatted JSON metadata

### Protecting the dashboard

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount Sinaliza::Engine => "/sinaliza"
end

# or with a simple constraint
mount Sinaliza::Engine => "/sinaliza", constraints: AdminConstraint.new
```

---

## Configuration

```ruby
# config/initializers/sinaliza.rb
Sinaliza.configure do |config|
  config.actor_method = :current_user
  config.default_source = "manual"
  config.record_request_info = true
  config.purge_after = 90.days
end
```

---

## Purging Old Events

If `purge_after` is configured:

```bash
bin/rails sinaliza:purge
```

Schedule it with cron, Heroku Scheduler, or whatever you prefer.

---

## Requirements

- Ruby >= 3.1
- Rails >= 7.1, < 9

---

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).
