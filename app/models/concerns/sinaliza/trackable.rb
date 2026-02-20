module Sinaliza
  module Trackable
    extend ActiveSupport::Concern

    included do
      has_many :events_as_actor,
               class_name: "Sinaliza::Event",
               as: :actor,
               dependent: :nullify

      has_many :events_as_target,
               class_name: "Sinaliza::Event",
               as: :target,
               dependent: :nullify
    end

    def track_event(name, target: nil, parent: nil, metadata: {})
      Sinaliza.record(
        name: name,
        actor: self,
        target: target,
        parent: parent,
        metadata: metadata,
        source: "model"
      )
    end

    def track_event_as_target(name, actor: nil, parent: nil, metadata: {})
      Sinaliza.record(
        name: name,
        actor: actor,
        target: self,
        parent: parent,
        metadata: metadata,
        source: "model"
      )
    end
  end
end
