class ReportSource < ActiveRecord::Base
  belongs_to :report
  belongs_to :source

end
