module Sinaliza
  class Interceptor < ApplicationRecord
    METHOD_TYPES = %w[instance class].freeze

    validates :target_class, presence: true
    validates :method_name, presence: true
    validates :event_name, presence: true
    validates :method_type, presence: true, inclusion: { in: METHOD_TYPES }
    validates :target_class, uniqueness: { scope: [ :method_name, :method_type ] }

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
  end
end
