class Report < ActiveRecord::Base
  has_many :report_sources
  has_many :sources, :through => :report_sources
  accepts_nested_attributes_for :report_sources, :allow_destroy => true

  def Report.prepare_temps(report)

    report_end = report.end || Time.now.utc
    
    temps = []
    report.sources.each do |source|
      temps << { :source => source,
        :readings =>  FahrenheitTemp.find(:all,
                                          :conditions => [ 'source_id = ? and sampled_at > ? and sampled_at < ?', source.id,  report.start, report_end],
                                          :order => :sampled_at) || [],
        :data => []
      }
    end
    return temps
  end

  def calculate_graph_data_for_source(reading_list, first_time, last_time, step_size)
    @data = []
    
    step_through_readings(reading_list, first_time, last_time, step_size) do |readings_in_bucket|
      @data << nil if readings_in_bucket.length == 0

      total = readings_in_bucket.inject(0) { |t, r| t = t + r.display_temp }
      @data << total.to_f / readings_in_bucket.length
    end


    return @data
  end

  def step_through_readings(reading_list, first_time, last_time, step_size)
    step_starts = first_time

    reading_index = 0
    while(step_starts <= last_time)
      step_ends = step_starts + step_size.minutes

      readings_this_step = []
      while(reading_index < reading_list.length &&
            reading_list[reading_index].sampled_at <= step_ends)
        readings_this_step << reading_list[reading_index]
        reading_index += 1
      end

      yield(readings_this_step)
      step_starts = step_ends
    end
  end



end
