module Sinaliza
  module InterceptorRegistry
    class << self
      def apply_all!
        Sinaliza::Interceptor.find_each do |interceptor|
          apply!(interceptor)
        end
      end

      def apply!(interceptor)
        key = interceptor.key

        # Store the authoritative interceptor ID for this key
        authoritative_ids[key] = interceptor.id

        # Only prepend the module once per key (prepend is permanent)
        unless prepended_keys.include?(key)
          klass = interceptor.target_class.constantize
          mod = build_module(key)

          if interceptor.method_type == "class"
            klass.singleton_class.prepend(mod)
          else
            klass.prepend(mod)
          end

          prepended_keys.add(key)
        end
      rescue NameError
        # Target class does not exist — skip
      end

      def applied?(interceptor)
        prepended_keys.include?(interceptor.key)
      end

      def authoritative_id_for(key)
        authoritative_ids[key]
      end

      def reset!
        authoritative_ids.clear
      end

      private

      def authoritative_ids
        @authoritative_ids ||= {}
      end

      def prepended_keys
        @prepended_keys ||= Set.new
      end

      def build_module(key)
        Module.new do
          method_name = key.include?("#") ? key.split("#").last : key.split(".").last

          define_method(method_name.to_sym) do |*args, **kwargs, &block|
            auth_id = Sinaliza::InterceptorRegistry.authoritative_id_for(key)
            record = auth_id ? Sinaliza::Interceptor.find_by(id: auth_id) : nil

            unless record&.active?
              return super(*args, **kwargs, &block)
            end

            metadata = {}

            if record.capture_args
              metadata[:args] = args.map(&:inspect)
              metadata[:kwargs] = kwargs.transform_values(&:inspect) if kwargs.any?
            end

            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) if record.capture_execution_time
            result = super(*args, **kwargs, &block)

            if record.capture_execution_time && start_time
              elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
              metadata[:execution_time_ms] = (elapsed * 1000).round(2)
            end

            metadata[:return] = result.inspect if record.capture_return

            Sinaliza.record(name: record.event_name, metadata: metadata, source: "interceptor")
            result
          end
        end
      end
    end
  end
end
