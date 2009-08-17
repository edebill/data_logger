class CreateReportParameters < ActiveRecord::Migration
  def self.up
    create_table :report_parameters do |t|
      t.timestamp :start
      t.timestamp :end

      t.timestamps
    end
  end

  def self.down
    drop_table :report_parameters
  end
end
