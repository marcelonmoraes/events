require "sinaliza/version"
require "sinaliza/engine"
require "sinaliza/configuration"

module Sinaliza
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def record(name:, actor: nil, target: nil, context: nil, parent: nil, metadata: {}, source: nil, ip_address: nil, user_agent: nil, request_id: nil)
      parent_id = parent.is_a?(Sinaliza::Event) ? parent.id : parent

      Sinaliza::Event.create!(
        name: name,
        actor: actor,
        target: target,
        context: context,
        parent_id: parent_id,
        metadata: metadata,
        source: source || configuration.default_source,
        ip_address: ip_address,
        user_agent: user_agent,
        request_id: request_id
      )
    end

    def record_later(name:, actor: nil, target: nil, context: nil, parent: nil, metadata: {}, source: nil, ip_address: nil, user_agent: nil, request_id: nil)
      attributes = {
        name: name,
        metadata: metadata,
        source: source || configuration.default_source,
        ip_address: ip_address,
        user_agent: user_agent,
        request_id: request_id
      }

      attributes[:actor] = actor.to_global_id.to_s if actor
      attributes[:target] = target.to_global_id.to_s if target
      attributes[:context] = context.to_global_id.to_s if context
      attributes[:parent_id] = parent.is_a?(Sinaliza::Event) ? parent.id : parent if parent

      Sinaliza::RecordEventJob.perform_later(attributes)
    end
  end
end
