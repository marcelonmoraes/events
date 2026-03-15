module Sinaliza
  class Interceptor < ApplicationRecord
    METHOD_TYPES = %w[instance class].freeze

    validates :target_class, presence: true
    validates :method_name, presence: true
    validates :event_name, presence: true
    validates :method_type, presence: true, inclusion: { in: METHOD_TYPES }
    validates :target_class, uniqueness: { scope: [ :method_name, :method_type ] }
    validate :target_class_exists
    validate :method_exists_on_target

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :by_target_class, ->(name) { where(target_class: name) }

    after_create :apply_interceptor
    after_destroy :deactivate!

    def activate!
      update!(active: true)
      apply_interceptor unless InterceptorRegistry.applied?(self)
    end

    def deactivate!
      update!(active: false) unless destroyed?
    end

    def key
      separator = method_type == "instance" ? "#" : "."
      "#{target_class}#{separator}#{method_name}"
    end

    private

    def apply_interceptor
      InterceptorRegistry.apply!(self)
    end

    def target_class_exists
      return if target_class.blank?

      target_class.constantize
    rescue NameError
      errors.add(:target_class, "\"#{target_class}\" does not exist")
    end

    def method_exists_on_target
      return if target_class.blank? || method_name.blank? || method_type.blank?

      klass = target_class.constantize
      available = method_type == "class" ? klass.methods : klass.instance_methods + klass.private_instance_methods

      return if available.include?(method_name.to_sym)

      errors.add(:method_name, "\"#{method_name}\" does not exist on #{target_class}")
    rescue NameError
      # target_class_exists already handles this
    end
  end
end
