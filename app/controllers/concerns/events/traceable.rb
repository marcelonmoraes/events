module Events
  module Traceable
    extend ActiveSupport::Concern

    class_methods do
      def track_event(name, only: nil, except: nil, metadata: {}, if: nil)
        callback_options = {}
        callback_options[:only] = only if only
        callback_options[:except] = except if except
        callback_options[:if] = binding.local_variable_get(:if) if binding.local_variable_get(:if)

        after_action(**callback_options) do
          resolved_metadata = metadata.is_a?(Proc) ? instance_exec(&metadata) : metadata
          record_event(name, metadata: resolved_metadata)
        end
      end
    end

    private

    def record_event(name, target: nil, parent: nil, metadata: {})
      actor = resolve_actor

      attributes = {
        name: name,
        actor: actor,
        target: target,
        parent: parent,
        metadata: metadata,
        source: "controller"
      }

      if Events.configuration.record_request_info
        attributes[:ip_address] = request.remote_ip
        attributes[:user_agent] = request.user_agent
        attributes[:request_id] = request.request_id
      end

      Events.record(**attributes)
    end

    def resolve_actor
      method = Events.configuration.actor_method
      send(method) if respond_to?(method, true)
    end
  end
end
