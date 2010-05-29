class Voltage < ActiveRecord::Base
  belongs_to :source
  validates_presence_of :source_id
  validates_numericality_of :voltage

  def parse(string)
    puts "voltage = #{string}"
    if md = string.match(/([^:])+:([^:])+/)
      self.voltage = Float(md[1])
      self.sampled_at = Time.at(md[2]) 
    else
      self.voltage = Float(string)
      self.sampled_at = Time.now
    end
    return self
  end
end
