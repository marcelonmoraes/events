# Changelog

## 0.2.1

- Add actor, target, and context usage guideline to README

## 0.2.0

- Add polymorphic `context` association for grouping events under a business object
- Add `by_context` and `by_context_type` query scopes
- Add `track_event_as_context` helper to Trackable concern
- Update monitor dashboard with context column, filter, and children count

## 0.1.3

- Fix Rails dependency constraint to >= 7.1, < 9

## 0.1.2

- Broaden Rails dependency to accept any version >= 7.0
- Add CI matrix testing Ruby 3.1–3.4 with Rails 7.1–8.1

## 0.1.1

- Broaden Rails dependency to accept any version >= 8.0

## 0.1.0

- Initial release
- Record events from models, controllers, or anywhere in your code
- Polymorphic actor and target support
- Nested events (parent/children hierarchy)
- Mountable monitor dashboard with filters
- Async event recording via ActiveJob
