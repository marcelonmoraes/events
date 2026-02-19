module Events
  class Event < ApplicationRecord
    belongs_to :actor, polymorphic: true, optional: true
    belongs_to :target, polymorphic: true, optional: true
    belongs_to :parent, class_name: "Events::Event", optional: true

    has_many :children, class_name: "Events::Event", foreign_key: :parent_id, dependent: :destroy

    validates :name, presence: true

    scope :by_name, ->(name) { where(name: name) }
    scope :by_source, ->(source) { where(source: source) }
    scope :by_actor_type, ->(type) { where(actor_type: type) }
    scope :since, ->(time) { where(created_at: time..) }
    scope :before, ->(time) { where(created_at: ..time) }
    scope :between, ->(from, to) { where(created_at: from..to) }
    scope :chronological, -> { order(created_at: :asc) }
    scope :reverse_chronological, -> { order(created_at: :desc) }
    scope :roots, -> { where(parent_id: nil) }
    scope :search, ->(query) {
      where("name LIKE :q OR source LIKE :q OR actor_type LIKE :q OR target_type LIKE :q", q: "%#{query}%")
    }

    def root?
      parent_id.nil?
    end

    def child?
      parent_id.present?
    end
  end
end
