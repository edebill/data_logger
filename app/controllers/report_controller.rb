class ReportController < ApplicationController
  def index
    respond_to do |format|
      format.html {
        @graph = open_flash_chart_object(600,300,url_for(:action => 'index',
                                                         :format => 'json'))
      }

      format.json {
        title = Title.new("Recent Temperatures")

        data1 = []



        temps = FahrenheitTemp.find(:all, :conditions => [ 'sampled_at >= ?', Time.now - 60 * 60 * 2 ],
                                    :order => :sampled_at)

        by_temp = temps.sort { |a,b| a.temp <=> b.temp }

        max = Integer(by_temp[-1].temp / 10.0) * 10 + 1
        min = Integer(by_temp[0].temp / 10.0) * 10



        x_labels = XAxisLabels.new
        x_labels.set_vertical()

        labels = []
        120.downto(0) do |n|
          time = Time.now - n * 60
          display_time = sprintf("%d:%02d", time.hour, time.min)
          if time.min % 15 == 0
            labels <<  XAxisLabel.new(display_time, '#0000ff', 20, 'diagonal')
          else
            labels << nil
          end
          
          tlist = []
          temps.each do |t|
            if t.sampled_at.hour == time.hour &&
                t.sampled_at.min == time.min
              tlist << t.temp
            end
            
          end
          data1 << tlist[0]
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


end
