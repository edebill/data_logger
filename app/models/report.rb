class Report < ActiveRecord::Base
  has_many :report_sources
  has_many :sources, :through => :report_sources
  accepts_nested_attributes_for :report_sources, :allow_destroy => true
end
