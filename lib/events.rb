require "events/version"
require "events/engine"
require "events/configuration"

module Events
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def record(name:, actor: nil, target: nil, metadata: {}, source: nil, ip_address: nil, user_agent: nil, request_id: nil)
      Events::Event.create!(
        name: name,
        actor: actor,
        target: target,
        metadata: metadata,
        source: source || configuration.default_source,
        ip_address: ip_address,
        user_agent: user_agent,
        request_id: request_id
      )
    end

    def record_later(name:, actor: nil, target: nil, metadata: {}, source: nil, ip_address: nil, user_agent: nil, request_id: nil)
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

      Events::RecordEventJob.perform_later(attributes)
    end
  end
end
