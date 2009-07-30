class FahrenheitTemp < ActiveRecord::Base
  belongs_to :source
  validates_presence_of :source_id
  validates_numericality_of :temp

  def parse(string)
    puts "temp = #{string}"
    self.temp = Float(string)

    return self
  end
  
end
