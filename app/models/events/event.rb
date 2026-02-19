module Events
  class Event < ApplicationRecord
    belongs_to :actor, polymorphic: true, optional: true
    belongs_to :target, polymorphic: true, optional: true

    validates :name, presence: true

    scope :by_name, ->(name) { where(name: name) }
    scope :by_source, ->(source) { where(source: source) }
    scope :by_actor_type, ->(type) { where(actor_type: type) }
    scope :since, ->(time) { where(created_at: time..) }
    scope :before, ->(time) { where(created_at: ..time) }
    scope :between, ->(from, to) { where(created_at: from..to) }
    scope :chronological, -> { order(created_at: :asc) }
    scope :reverse_chronological, -> { order(created_at: :desc) }
    scope :search, ->(query) {
      where("name LIKE :q OR source LIKE :q OR actor_type LIKE :q OR target_type LIKE :q", q: "%#{query}%")
    }
  end
end
