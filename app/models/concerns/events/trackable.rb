module Events
  module Trackable
    extend ActiveSupport::Concern

    included do
      has_many :events_as_actor,
               class_name: "Events::Event",
               as: :actor,
               dependent: :nullify

      has_many :events_as_target,
               class_name: "Events::Event",
               as: :target,
               dependent: :nullify
    end

    def track_event(name, target: nil, metadata: {})
      Events.record(
        name: name,
        actor: self,
        target: target,
        metadata: metadata,
        source: "model"
      )
    end

    def track_event_as_target(name, actor: nil, metadata: {})
      Events.record(
        name: name,
        actor: actor,
        target: self,
        metadata: metadata,
        source: "model"
      )
    end
  end
end
