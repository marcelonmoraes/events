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

        klass = interceptor.target_class.constantize
        target = interceptor.method_type == "class" ? klass.singleton_class : klass
        class_id = target.object_id

        # Only prepend if the class object changed (reloaded) or never prepended
        unless prepended_classes[key] == class_id
          mod = build_module(key)
          target.prepend(mod)
          prepended_classes[key] = class_id
        end
      rescue NameError
        # Target class does not exist — skip
      end

      def applied?(interceptor)
        prepended_classes.key?(interceptor.key)
      end

      def authoritative_id_for(key)
        authoritative_ids[key]
      end

      def reset!
        prepended_classes.clear
        authoritative_ids.clear
      end

      private

      def authoritative_ids
        @authoritative_ids ||= {}
      end

      def prepended_classes
        @prepended_classes ||= {}
      end

      def build_module(key)
        is_instance = key.include?("#")

        Module.new do
          method_name = is_instance ? key.split("#").last : key.split(".").last

          define_method(method_name.to_sym) do |*args, **kwargs, &block|
            # Prevent reentrant recording (e.g. ActiveRecord calling save internally)
            thread_key = :"_sinaliza_interceptor_#{key}"
            if Thread.current[thread_key]
              return super(*args, **kwargs, &block)
            end

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

            begin
              Thread.current[thread_key] = true
              start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) if record.capture_execution_time
              result = super(*args, **kwargs, &block)
            ensure
              Thread.current[thread_key] = nil
            end

            if record.capture_execution_time && start_time
              elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
              metadata[:execution_time_ms] = (elapsed * 1000).round(2)
            end

            metadata[:return] = result.inspect if record.capture_return

            event_attrs = { name: record.event_name, metadata: metadata, source: "interceptor" }

            # For instance methods, self is the target object
            if is_instance && self.class < ActiveRecord::Base
              event_attrs[:target] = self
            end

            Sinaliza.record(**event_attrs)
            result
          end
        end
      end
    end
  end
end
