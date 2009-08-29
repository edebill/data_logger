class ReportController < ApplicationController
  def index
    @report = Report.new(params[:report])
    @report.start = Time.now  - (60 * 60 * 24 * 2) || @report.start
    @sources = Source.find(:all, :order => :name)
  end

  def show


    params[:report][:sources] = params[:report][:sources].collect {|s| Source.find(s.to_i)}
    
    
    @report = Report.new(params[:report])
    unless @report.start
      logger.debug("defaulting report start to 2 days ago")
      @report.start = Time.now - (60 * 60 * 24 * 2)
    end
    @source = @report.sources[0]
    unless @source
      return render(  :file =>  "#{RAILS_ROOT}/public/404.html", :status => :not_found)
    end
    @sources = Source.find(:all, :order => :name)
 
    respond_to do |format|
      format.html {
        @graph = open_flash_chart_object(800,700,url_for(:action => 'show',
                                                         :format => 'json',
                                                         :report => {
                                                           :start => @report.start,
                                                           :end => @report.end,
                                                           :sources =>  @report.sources.collect {|s| s.id }}))
      }

      format.json {
        title = Title.new("Recent Temperatures")


        temps = ReportController.prepare_temps(@report)

        (first_reading, last_reading) = ReportController.find_first_and_last_reading(temps)
        step_size = ReportController.calculate_step_size(first_reading, last_reading)
        (first_time, last_time) = ReportController.calculate_first_and_last_time(first_reading, last_reading, step_size)
        # kind of subtle - start at calculated first time, but needs
        # actual last reading
        x = x_axis(first_time, last_reading, step_size)
        



        (highest_reading, lowest_reading) = ReportController.find_highest_and_lowest_readings(temps)

        max = Integer(highest_reading / 5.0) * 5 + 5
        min = Integer(lowest_reading / 5.0) * 5

        
        temps.each do |source|
          t = source[:readings]

          source[:data] = calculate_graph_data_for_source(t, first_time, last_reading, step_size)
        end


        y = YAxis.new
        y.set_range(min,max,5)

        x_legend = XLegend.new("Time")
        x_legend.set_style('{font-size: 20px; color: #778877}')

        y_legend = YLegend.new("degrees Fahrenheit")
        y_legend.set_style('{font-size: 20px; color: #770077}')


        chart =OpenFlashChart.new
        chart.set_title(title)
        chart.set_x_legend(x_legend)
        chart.set_y_legend(y_legend)
        chart.y_axis = y
        chart.x_axis = x

        colors = [ '#000000', '#FF0000', '#00FF00',  '#0000FF']
        temps.each do |source|
          line_dot = LineDot.new
          line_dot.text = source[:source].name
          line_dot.width = 1
          line_dot.colour = colors.shift || '#999999'
          line_dot.dot_size = 2
          line_dot.values = source[:data]
          chart.add_element(line_dot)
        end

        render :text => chart.to_s
      }
    end
  end


  protected

  def self.find_first_and_last_reading(temps)
    first = nil
    last = nil
    temps.each do |source|
      t = source[:readings]

      if t[0].blank?
        next
      end
      if  first == nil || t[0].sampled_at < first
        first = t[0].sampled_at
      end

      if last == nil || t[-1].sampled_at > last
        last = t[-1].sampled_at
      end
    end
    return first, last
  end

  def self.calculate_step_size(first, last)

    secs = last - first

    minutes = secs/60

    possible_steps = [1, 5, 10, 15, 20, 30, 60, 120, 240, 360, 720]
    step = 1
    while (minutes / step) > 200
      step = possible_steps.shift
    end

    return step
  end

  def self.calculate_first_and_last_time(first, last, step_size)

    return Time.at(Integer((first.to_i / 60.0) / step_size) * step_size * 60), 
           Time.at((((last.to_i / 60.0).to_i / step_size) + 1) * step_size * 60)
  end

  def x_axis(first_time, last_time, step_size)
    x_labels = XAxisLabels.new
    labels = []

    step_through_times(first_time, last_time, step_size) do |this_step, next_step, step_no| 

      display_time = this_step.strftime("%b %d, %k:%M %Z")
      
      if step_no % 5 == 0
        labels <<  XAxisLabel.new(display_time, '#0000ff', 20, 80)
      else 
        labels << nil
      end
    end

    x_labels.labels = labels

    x = XAxis.new
    x.set_labels(x_labels)

    return x
  end

  def self.find_highest_and_lowest_readings(temps)
    logger.debug("find highest and lowest readings")
    highest = nil
    lowest = nil
    temps.each do |source|
      logger.debug("checking highest and lowest for #{source[:source].name}")
      t = source[:readings]
      next if t.blank?
      by_temp = t.sort { |x, y| x.temp <=> y.temp }
      logger.debug("#{by_temp[0].temp} - #{by_temp[-1].temp}")
      if lowest == nil || by_temp[0].temp < lowest
        lowest = by_temp[0].temp
      end
      if highest == nil || by_temp[-1].temp > highest
        highest = by_temp[-1].temp
      end
    end

    return highest, lowest
  end
  
  def calculate_graph_data_for_source(temps, first_time, last_reading, step_size)
    data = []
    total = 0.0
    count = nil

    step_through_times(first_time, last_reading, step_size) do |this_step, next_step, step_no|
      temps.each do |t|
        if t.sampled_at > this_step && t.sampled_at <= next_step
          total += t.temp
          count = count.to_i + 1  # in case it is nil
        end
      end
      
      if(count.nil?)
        data << nil
      else
        data << total / count
      end
    end

    return data
  end

  def step_through_times(first_time, last_time, step_size)
    this_step = first_time
    step_no = 0
    while this_step < last_time
      next_step = this_step + 60 * step_size

      yield(this_step, next_step, step_no)

      this_step = next_step
      step_no += 1
    end
  end


  def self.prepare_temps(report)

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

end