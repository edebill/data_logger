class FahrenheitTempsController < ApplicationController
  # GET /fahrenheit_temps
  # GET /fahrenheit_temps.xml
  def index
    @fahrenheit_temps = FahrenheitTemp.find(:all, :order => :sampled_at)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fahrenheit_temps }
    end
  end

  # GET /fahrenheit_temps/1
  # GET /fahrenheit_temps/1.xml
  def show
    @fahrenheit_temp = FahrenheitTemp.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fahrenheit_temp }
    end
  end

  # GET /fahrenheit_temps/new
  # GET /fahrenheit_temps/new.xml
  def new
    @fahrenheit_temp = FahrenheitTemp.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fahrenheit_temp }
    end
  end

  # GET /fahrenheit_temps/1/edit
  def edit
    @fahrenheit_temp = FahrenheitTemp.find(params[:id])
  end

  # POST /fahrenheit_temps
  # POST /fahrenheit_temps.xml
  def create
    @fahrenheit_temp = FahrenheitTemp.new(params[:fahrenheit_temp])

    respond_to do |format|
      if @fahrenheit_temp.save
        flash[:notice] = 'FahrenheitTemp was successfully created.'
        format.html { redirect_to(@fahrenheit_temp) }
        format.xml  { render :xml => @fahrenheit_temp, :status => :created, :location => @fahrenheit_temp }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fahrenheit_temp.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fahrenheit_temps/1
  # PUT /fahrenheit_temps/1.xml
  def update
    @fahrenheit_temp = FahrenheitTemp.find(params[:id])

    respond_to do |format|
      if @fahrenheit_temp.update_attributes(params[:fahrenheit_temp])
        flash[:notice] = 'FahrenheitTemp was successfully updated.'
        format.html { redirect_to(@fahrenheit_temp) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @fahrenheit_temp.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fahrenheit_temps/1
  # DELETE /fahrenheit_temps/1.xml
  def destroy
    @fahrenheit_temp = FahrenheitTemp.find(params[:id])
    @fahrenheit_temp.destroy

    respond_to do |format|
      format.html { redirect_to(fahrenheit_temps_url) }
      format.xml  { head :ok }
    end
  end
end
