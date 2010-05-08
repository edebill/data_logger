class CreateVoltages < ActiveRecord::Migration
  def self.up
    create_table :voltages do |t|
      t.float :voltage
      t.integer :source_id
      t.datetime :sampled_at

      t.timestamps
    end
  end

  def self.down
    drop_table :voltages
  end
end
