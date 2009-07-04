require 'crc16'

class LogEvent

  # event_type:source:event data...
  def self.parse(event_string)
    if md = event_string.match(/(([^:]+):([^:]+):(.+)):([^:]+)/)

      event = case md[2]
              when "T" then TimePeriod.new()
              end

      if event
        crc = Crc16.new.crc16(md[1])
        unless crc == md[5] 
          event.errors.add_to_base("invalid - failed CRC check")
          return event
        end
        event.source = Source.get(md[3]) 
        event.parse(md[4])
        return event
      end      
    end

    return nil
  end

end
