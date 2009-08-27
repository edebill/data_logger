class AddSourceToReportParameters < ActiveRecord::Migration
  def self.up
    add_column :report_parameters, :source, :string
  end

  def self.down
    remove_column :report_parameters, :source
  end
end
