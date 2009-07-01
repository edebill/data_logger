class CreateTimePeriods < ActiveRecord::Migration
  def self.up
    create_table :time_periods do |t|
      t.integer :source_id
      t.datetime :time_start
      t.datetime :time_end

      t.timestamps
    end
  end

  def self.down
    drop_table :time_periods
  end
end
