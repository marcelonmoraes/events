module Sinaliza
  class RecordEventJob < ApplicationJob
    queue_as :default

    def perform(attributes)
      attributes = attributes.symbolize_keys

      if attributes[:actor].is_a?(String)
        attributes[:actor] = GlobalID::Locator.locate(attributes[:actor])
      end

      if attributes[:target].is_a?(String)
        attributes[:target] = GlobalID::Locator.locate(attributes[:target])
      end

      Sinaliza::Event.create!(attributes)
    end
  end
end
