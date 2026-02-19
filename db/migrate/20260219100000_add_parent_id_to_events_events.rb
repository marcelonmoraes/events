class AddParentIdToEventsEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events_events, :parent, null: true, foreign_key: { to_table: :events_events }, index: true
  end
end
