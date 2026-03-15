class CreateSinalizaInterceptors < ActiveRecord::Migration[8.0]
  def change
    create_table :sinaliza_interceptors do |t|
      t.string :target_class, null: false
      t.string :method_name, null: false
      t.string :method_type, null: false, default: "instance"
      t.string :event_name, null: false
      t.boolean :capture_args, default: false
      t.boolean :capture_return, default: false
      t.boolean :capture_execution_time, default: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :sinaliza_interceptors, [ :target_class, :method_name, :method_type ],
              unique: true, name: "idx_sinaliza_interceptors_uniqueness"
    add_index :sinaliza_interceptors, :active
  end
end
