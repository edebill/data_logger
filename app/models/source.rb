class Source < ActiveRecord::Base

  def self.get(name)
    self.find_by_name(name) || self.new(:name => name)
  end

end
