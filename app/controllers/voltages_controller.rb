class VoltagesController < ApplicationController
  # GET /voltages
  # GET /voltages.xml
  def index
    @voltages = Voltage.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @voltages }
    end
  end

  # GET /voltages/1
  # GET /voltages/1.xml
  def show
    @voltage = Voltage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @voltage }
    end
  end

  # GET /voltages/new
  # GET /voltages/new.xml
  def new
    @voltage = Voltage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @voltage }
    end
  end

  # GET /voltages/1/edit
  def edit
    @voltage = Voltage.find(params[:id])
  end

  # POST /voltages
  # POST /voltages.xml
  def create
    @voltage = Voltage.new(params[:voltage])

    respond_to do |format|
      if @voltage.save
        flash[:notice] = 'Voltage was successfully created.'
        format.html { redirect_to(@voltage) }
        format.xml  { render :xml => @voltage, :status => :created, :location => @voltage }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @voltage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /voltages/1
  # PUT /voltages/1.xml
  def update
    @voltage = Voltage.find(params[:id])

    respond_to do |format|
      if @voltage.update_attributes(params[:voltage])
        flash[:notice] = 'Voltage was successfully updated.'
        format.html { redirect_to(@voltage) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @voltage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /voltages/1
  # DELETE /voltages/1.xml
  def destroy
    @voltage = Voltage.find(params[:id])
    @voltage.destroy

    respond_to do |format|
      format.html { redirect_to(voltages_url) }
      format.xml  { head :ok }
    end
  end
end
