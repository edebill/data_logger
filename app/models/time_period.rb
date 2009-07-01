class TimePeriod < ActiveRecord::Base
  belongs_to :source
  validates_presence_of :time_start, :time_end


  def parse(string)
    if md = string.match(/(\d+):(\d+)/)
      self.time_start = Time.at(Integer(md[1]))
      self.time_end = Time.at(Integer(md[2]))
    else
      self.errors.add_to_base "Unable to parse event string"
    end

    return self
  end

end
