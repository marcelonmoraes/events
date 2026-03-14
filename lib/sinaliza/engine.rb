module Sinaliza
  class Engine < ::Rails::Engine
    isolate_namespace Sinaliza

    initializer "sinaliza.interceptors", after: :load_config_initializers do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.connection_pool.with_connection do
          if ActiveRecord::Base.connection.table_exists?(:sinaliza_interceptors)
            Sinaliza::InterceptorRegistry.apply_all!
          end
        end
      rescue ActiveRecord::NoDatabaseError
        # Database not created yet — skip
      end
    end
  end
end
