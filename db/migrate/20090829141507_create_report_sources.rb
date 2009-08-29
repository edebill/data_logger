class CreateReportSources < ActiveRecord::Migration
  def self.up
    create_table :report_sources do |t|
      t.integer :report_id
      t.integer :source_id

      t.timestamps
    end

    add_index :report_sources, :report_id
    add_index :report_sources, :source_id

    remove_column :report_parameters, :source
  end

  def self.down
    drop_table :report_sources
    add_column :report_parameters, :source, :string
  end
end
