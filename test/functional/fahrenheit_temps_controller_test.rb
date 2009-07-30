require 'test_helper'

class FahrenheitTempsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fahrenheit_temps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fahrenheit_temp" do
    assert_difference('FahrenheitTemp.count') do
      post :create, :fahrenheit_temp => { }
    end

    assert_redirected_to fahrenheit_temp_path(assigns(:fahrenheit_temp))
  end

  test "should show fahrenheit_temp" do
    get :show, :id => fahrenheit_temps(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fahrenheit_temps(:one).to_param
    assert_response :success
  end

  test "should update fahrenheit_temp" do
    put :update, :id => fahrenheit_temps(:one).to_param, :fahrenheit_temp => { }
    assert_redirected_to fahrenheit_temp_path(assigns(:fahrenheit_temp))
  end

  test "should destroy fahrenheit_temp" do
    assert_difference('FahrenheitTemp.count', -1) do
      delete :destroy, :id => fahrenheit_temps(:one).to_param
    end

    assert_redirected_to fahrenheit_temps_path
  end
end
