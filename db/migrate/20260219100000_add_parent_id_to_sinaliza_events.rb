class AddParentIdToSinalizaEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :sinaliza_events, :parent, null: true, foreign_key: { to_table: :sinaliza_events }, index: true
  end
end
