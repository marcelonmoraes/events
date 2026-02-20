class AddContextToSinalizaEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :sinaliza_events, :context, polymorphic: true, index: true
  end
end
