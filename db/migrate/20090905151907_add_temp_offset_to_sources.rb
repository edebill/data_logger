class AddTempOffsetToSources < ActiveRecord::Migration
  def self.up
    add_column :sources, :temp_offset, :float
  end

  def self.down
    remove_column :source, :temp_offset
  end
end
