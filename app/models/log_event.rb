require 'crc16'

class LogEvent

  # event_type:source:event data...
  def self.parse(event_string)
    if md = event_string.match(/(([^:]+):([^:]+):(.+):)([^:]+)/)

      event = case md[2]
              when "P" then TimePeriod.new()
              when "T" then FahrenheitTemp.new()
              when "V" then Voltage.new()
              end

      if event
        crc = sprintf("%04X", Crc16.new.crc16(md[1]))
        unless crc == md[5] 
          event.errors.add_to_base("invalid - failed CRC check")
          return event
        end

        source = Source.get(md[3])
        source.save unless source.id

        event.source = source
        event.parse(md[4])
        return event
      end      
    end

    return nil
  rescue ArgumentError => e
    Rails.logger.warn("invalid byte sequence - #{e} in '#{event_string}'")
  end

end
