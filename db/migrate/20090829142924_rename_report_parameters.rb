class RenameReportParameters < ActiveRecord::Migration
  def self.up
    rename_table :report_parameters, :reports
  end

  def self.down
    rename_table :reports, :report_parameters
  end
end
