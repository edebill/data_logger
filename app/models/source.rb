class Source < ActiveRecord::Base
  has_many :report_sources
  has_many :reports, :through => :report_sources

  def self.get(name)
    self.find_by_name(name) || self.new(:name => name)
  end

end
