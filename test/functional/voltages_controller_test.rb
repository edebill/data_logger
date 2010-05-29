require 'test_helper'

class VoltagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:voltages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create voltage" do
    assert_difference('Voltage.count') do
      post :create, :voltage => { }
    end

    assert_redirected_to voltage_path(assigns(:voltage))
  end

  test "should show voltage" do
    get :show, :id => voltages(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => voltages(:one).to_param
    assert_response :success
  end

  test "should update voltage" do
    put :update, :id => voltages(:one).to_param, :voltage => { }
    assert_redirected_to voltage_path(assigns(:voltage))
  end

  test "should destroy voltage" do
    assert_difference('Voltage.count', -1) do
      delete :destroy, :id => voltages(:one).to_param
    end

    assert_redirected_to voltages_path
  end
end
