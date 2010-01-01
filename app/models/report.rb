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



end
