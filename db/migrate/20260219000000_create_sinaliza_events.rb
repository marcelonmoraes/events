class CreateSinalizaEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :sinaliza_events do |t|
      t.string :name, null: false
      t.references :actor, polymorphic: true, index: true
      t.references :target, polymorphic: true, index: true
      t.json :metadata, default: {}
      t.string :source, default: "manual"
      t.string :ip_address
      t.string :user_agent
      t.string :request_id

      t.timestamps
    end

    add_index :sinaliza_events, :name
    add_index :sinaliza_events, :source
    add_index :sinaliza_events, :created_at
  end
end
