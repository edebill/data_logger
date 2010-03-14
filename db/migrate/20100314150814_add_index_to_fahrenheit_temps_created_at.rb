class AddIndexToFahrenheitTempsCreatedAt < ActiveRecord::Migration
  def self.up
    add_index :fahrenheit_temps, :created_at
  end

  def self.down
    remove_index :fahrenheit_temps, :created_at
  end
end
