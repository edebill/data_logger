class AddLoggedAtToFahrenheitTemp < ActiveRecord::Migration
  def self.up
    add_column :fahrenheit_temps, :sampled_at, :datetime
    execute("update fahrenheit_temps set sampled_at = created_at where sampled_at is null")
  end

  def self.down
    remove_column :fahrenheit_temps, :sampled_at
  end
end
