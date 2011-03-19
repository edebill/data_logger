DataLogger::Application.routes.draw do
  resources :voltages, :fahrenheit_temps, :time_periods

  resources :sources do |source|
    resources :fahrenheit_temps, :collection => [:latest]
  end

  match '/:controller/:action'
  root :to => "report#index"
end
