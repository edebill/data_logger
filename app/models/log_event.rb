class LogEvent

  # event_type:source:event data...
  def self.parse(event_string)
    if md = event_string.match(/([^:]+):([^:]+):(.+)/)

      event = case md[1]
              when "T" then TimePeriod.new()
              end

      if event
        event.source = Source.get(md[2]) 
        event.parse(md[3])
        return event
      end      
    end

    return nil
  end

end
