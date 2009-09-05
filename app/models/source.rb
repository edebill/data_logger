class Source < ActiveRecord::Base
  has_many :report_sources
  has_many :reports, :through => :report_sources

  validates_numericality_of :temp_offset, :only_integer => false

  def self.get(name)
    self.find_by_name(name) || self.new(:name => name)
  end

end
