module Events
  class Configuration
    attr_accessor :actor_method, :default_source, :record_request_info, :purge_after

    def initialize
      @actor_method = :current_user
      @default_source = "manual"
      @record_request_info = true
      @purge_after = nil
    end
  end
end
