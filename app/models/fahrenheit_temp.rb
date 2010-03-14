class FahrenheitTemp < ActiveRecord::Base
  belongs_to :source
  validates_presence_of :source_id
  validates_numericality_of :temp

  def display_time
    self.created_at.asctime
  end

  def display_temp
    if self.source.temp_offset.nil?
      self.temp
    else
      self.temp + self.source.temp_offset
    end
  end

  def parse(string)
    puts "temp = #{string}"
    if md = string.match(/([^:])+:([^:])+/)
      self.temp = Float(md[1])
      self.sampled_at = Time.at(md[2]) 
    else
      self.temp = Float(string)
      self.sampled_at = Time.now
    end
    return self
  end
  
end
