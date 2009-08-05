class ReportController < ApplicationController
  def index
    respond_to do |format|
      format.html {
        @graph = open_flash_chart_object(800,500,url_for(:action => 'index',
                                                         :format => 'json'))
      }

      format.json {
        title = Title.new("Recent Temperatures")

        data1 = []
        source = Source.find_by_name("ds_reader")
        temps = FahrenheitTemp.find(:all,
                                    :conditions => [ 'source_id = ?', source.id],
                                    :order => :sampled_at)

        step_size = ReportController.calculate_step_size(temps)
        first_time = ReportController.calculate_first_time(temps[0].sampled_at, step_size)
        
        by_temp = temps.sort { |a,b| a.temp <=> b.temp }

        max = Integer(by_temp[-1].temp / 5.0) * 5 + 5
        min = Integer(by_temp[0].temp / 5.0) * 5

        x_labels = XAxisLabels.new

        labels = []
        seconds_diff = temps[-1].sampled_at - temps[0].sampled_at
        steps = Integer((seconds_diff / 60.0) / step_size) * step_size + step_size

        step_time = first_time
        step_no = 0
        while step_time < temps[-1].sampled_at
          next_step = step_time + 60 * step_size

          display_time = sprintf("%s %d, %d:%02d", step_time.month, step_time.day, step_time.hour, step_time.min)
          
          if step_no % 5 == 0
            labels <<  XAxisLabel.new(display_time, '#0000ff', 20, 80)
          else 
            labels << nil
          end
          
          tlist = []
          temps.each do |t|
            if t.sampled_at > step_time &&
                t.sampled_at <=  next_step
              tlist << t.temp
            end
            
          end
          data1 << tlist[0]
          step_time = next_step
          step_no += 1
        end

        x_labels.labels = labels

        x = XAxis.new
        x.set_labels(x_labels)


        line_dot = LineDot.new
        line_dot.text = "Line Dot"
        line_dot.width = 1
        line_dot.colour = '#5E4725'
        line_dot.dot_size = 2
        line_dot.values = data1

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

        chart.add_element(line_dot)

        render :text => chart.to_s
      }
    end
  end


  protected

  def self.calculate_step_size(temps)
    secs = temps[-1].sampled_at - temps[0].sampled_at

    minutes = secs/60

    possible_steps = [1, 5, 10, 15, 20, 30, 60, 120, 240, 360, 720]
    step = 1
    while minutes / step > 200
      step = possible_steps.shift
    end

    return step
  end

  def self.calculate_first_time(earliest, step_size)
    return Time.at(Integer((earliest.to_i / 60.0) / step_size) * step_size * 60)
  end
end
