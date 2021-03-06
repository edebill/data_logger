class ReportController < ApplicationController
  def index
    @report = Report.new(params[:report])
    @report.start = Time.now  - (60 * 60 * 24 * 2) || @report.start
    @sources = Source.find(:all, :order => :name)
  end

  def manual
    @title = "Temperature Report"

    params[:report][:sources] = params[:report][:sources].collect {|s| Source.find(s.to_i)}
    
    @report = Report.new(params[:report])
    
    show_report()
  end

  def latest_temps
    @title = "Latest Temperatures"

    @temps = FahrenheitTemp.find(:all, :conditions => ['created_at > ? ', Time.now - 30.minutes])
    
    @sources = []

    @temps.map do |t|
      unless @sources.include? t.source_id
        @sources << t.source_id
      end
    end

    @custom_script =  <<SCRIPT
var updateTemp = function updateTemp(source) {
   $.getJSON('/sources/' + source + '/fahrenheit_temps/latest.json', function(data) {
         $('#temp_source_' + source).replaceWith('<div id="temp_source_' + source + '"  class="big_data_block">  <div class="big_data_source">' + data.fahrenheit_temp.source.name + '</div><div class="big_data_value">' + data.fahrenheit_temp.display_temp + '</div><div class="big_data_time">' + data.fahrenheit_temp.display_time + '</div></div>') } );
}   
 $(document).ready(function() {
 
SCRIPT

    @sources.each do |s|
      @custom_script += <<SCRIPT
  $('#content').append('<div id="temp_source_#{ s }" class="big_data_block"></div>')
  updateTemp(#{ s });
  window.setInterval("updateTemp(#{ s })", 30000);

SCRIPT
end
    @custom_script  += "});"
  end

  def latest_trends
    @title = "Latest Temperature Trends"
    start = Time.now.utc   # when this comes from user input, Rails gets it right
                # we need to manually set it here.

    count = 0

    while count == 0 do
      start = start - 1.day
      count = FahrenheitTemp.count(:conditions => ['sampled_at > ?', start])
    end

    latest_sources = FahrenheitTemp.find(:all, :group => 'source_id',
                                         :select => 'source_id',
                                         :conditions => ['sampled_at > ?', start])


    @report = Report.new(:sources => latest_sources.collect {|s| Source.find(s.source_id)},
                         :start => start)

    @dataset = @report.to_flot_json
  end



  def show_report
    unless @report.start
      logger.debug("defaulting report start to 2 days ago")
      @report.start = Time.now - (60 * 60 * 24 * 2)
    end

    @source = @report.sources[0]
    unless @source
      return render(  :file =>  "#{RAILS_ROOT}/public/404.html", :status => :not_found)
    end
 
    respond_to do |format|
      format.html { # setting size doesn't actually work - it always does 800x700
        @graph = open_flash_chart_object(800,700,url_for(:action => 'data',
                                                         :format => 'json',
                                                         :report => {
                                                           :start => @report.start,
                                                           :end => @report.end,
                                                           :sources =>  @report.sources.collect {|s| s.id }}))
        render :template => 'report/show'
      }

    end
  end

  def data 

    params[:report][:sources] = params[:report][:sources].collect {|s| Source.find(s.to_i)}
    
    @report = Report.new(params[:report])
    logger.debug(@report.inspect)

    unless @report.start
      logger.debug("defaulting report start to 2 days ago")
      @report.start = Time.now - (60 * 60 * 24 * 2)
    end

    @source = @report.sources[0]

    unless @source
      return render(  :file =>  "#{RAILS_ROOT}/public/404.html", :status => :not_found)
    end

    respond_to do |format|
      format.json {
        title = Title.new("Recent Temperatures")


        temps = Report.prepare_temps(@report)
        logger.debug(temps.inspect)
        (first_reading, last_reading) = ReportController.find_first_and_last_reading(temps)
        step_size = ReportController.calculate_step_size(first_reading, last_reading)
        (first_time, last_time) = ReportController.calculate_first_and_last_time(first_reading, last_reading, step_size)
        # kind of subtle - start at calculated first time, but needs
        # actual last reading
        x = x_axis(first_time, last_reading, step_size)
        
        
        temps.each do |source|
          t = source[:readings]

          source[:data] = @report.calculate_graph_data_for_source(t, first_time, last_reading, step_size)
        end

        (highest_reading, lowest_reading) = ReportController.find_highest_and_lowest_readings(temps)
        max = Integer(highest_reading / 5.0) * 5 + 5
        min = Integer(lowest_reading / 5.0) * 5

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

    possible_steps = [1, 5, 10, 15, 20, 30, 60, 120, 240, 360, 720, 1440, 2880]
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
        labels <<  XAxisLabel.new(display_time, '#0000ff', 10, 80)
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
      data_list = source[:data].compact    # remove any nil entries
      next if 0 == data_list.length        # skip this one if they were all nil

      sorted_by_temp = data_list.sort

      if lowest == nil || sorted_by_temp[0] < lowest
        lowest = sorted_by_temp[0]
      end
      if highest == nil || sorted_by_temp[-1] > highest
        highest = sorted_by_temp[-1]
      end
    end

    return highest, lowest
  end
  



  def step_through_times(first_time, last_time, step_size)
    this_step = first_time
    next_step = first_time

    step_no = 0

    while next_step < last_time
      next_step = this_step + 60 * step_size
      yield(this_step, next_step, step_no)

      step_no +=1
      this_step = next_step
    end
  end


end
