class TimePeriodsController < ApplicationController
  # GET /time_periods
  # GET /time_periods.xml
  def index
    @time_periods = TimePeriod.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @time_periods }
    end
  end

  # GET /time_periods/1
  # GET /time_periods/1.xml
  def show
    @time_period = TimePeriod.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @time_period }
    end
  end

  # GET /time_periods/new
  # GET /time_periods/new.xml
  def new
    @time_period = TimePeriod.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @time_period }
    end
  end

  # GET /time_periods/1/edit
  def edit
    @time_period = TimePeriod.find(params[:id])
  end

  # POST /time_periods
  # POST /time_periods.xml
  def create
    @time_period = TimePeriod.new(params[:time_period])

    respond_to do |format|
      if @time_period.save
        flash[:notice] = 'TimePeriod was successfully created.'
        format.html { redirect_to(@time_period) }
        format.xml  { render :xml => @time_period, :status => :created, :location => @time_period }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @time_period.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /time_periods/1
  # PUT /time_periods/1.xml
  def update
    @time_period = TimePeriod.find(params[:id])

    respond_to do |format|
      if @time_period.update_attributes(params[:time_period])
        flash[:notice] = 'TimePeriod was successfully updated.'
        format.html { redirect_to(@time_period) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @time_period.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /time_periods/1
  # DELETE /time_periods/1.xml
  def destroy
    @time_period = TimePeriod.find(params[:id])
    @time_period.destroy

    respond_to do |format|
      format.html { redirect_to(time_periods_url) }
      format.xml  { head :ok }
    end
  end
end
