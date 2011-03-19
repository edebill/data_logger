class AddSampledAtIndexToFahrenheitTemps < ActiveRecord::Migration
  def self.up
    add_index :fahrenheit_temps, :sampled_at
  end

  def self.down
    remove_index :fahrenheit_temps, :sampled_at
  end
end
