require 'test_helper'
require 'ostruct'

class ReportTest < ActiveRecord::TestCase

  context "ReportController:" do
    context "One reading per minute (1 minute step)" do
      setup do
        @r = Report.new
        @input = [] 
        last = Time.now
        10.times do |i|
          last = last + 1.minute
          @input << OpenStruct.new(:display_temp => i,
                                   :sampled_at => last)
          puts "reading: #{i} at #{last}"

        end
      end
      
      context "1 minute step" do
        setup do
          puts "inputs has #{@input.length} readings"
          @results = @r.calculate_graph_data_for_source(@input, 
                                                       @input[0].sampled_at - 2.seconds, 
                                                       @input[-1].sampled_at + 1.seconds,
                                                       1)
          puts @results.inspect
        end

        should "have 10 periods" do
          assert_equal 10, @results.length
        end
        
        should "have same values as inputs" do
          @input.length.times do |i|
            assert_equal @input[i].display_temp, @results[i]
          end
        end
      end

      context "2 minute step" do
        setup do
          puts "inputs has #{@input.length} readings"
          @results = @r.calculate_graph_data_for_source(@input, 
                                                       @input[0].sampled_at - 2.seconds, 
                                                       @input[-1].sampled_at + 1.seconds,
                                                       2)
          puts @results.inspect
        end

        should "have 5 periods" do
          assert_equal 5, @results.length
        end
        
        should "have same correct values" do
          assert_equal 0.5, @results[0]
          assert_equal 2.5, @results[1]
        end
      end


      context "an empty step" do
        setup do
          puts "inputs has #{@input.length} readings"
          @input = [@input[0]]
          @results = @r.calculate_graph_data_for_source(@input, 
                                                       @input[0].sampled_at - 2.seconds, 
                                                       @input[0].sampled_at - 2.seconds + 20.minutes,
                                                       10)
          puts @results.inspect
        end

        should "have 2 periods" do
          assert_equal 2, @results.length
        end
        
        should "have same correct values" do
          assert_equal nil, @results[1]
        end
      end
    end
  end
end
