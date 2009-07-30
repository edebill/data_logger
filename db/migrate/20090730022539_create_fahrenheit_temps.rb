class CreateFahrenheitTemps < ActiveRecord::Migration
  def self.up
    create_table :fahrenheit_temps do |t|
      t.float :temp
      t.integer :source_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fahrenheit_temps
  end
end
