require 'test_helper'

class TimePeriodsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:time_periods)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create time_period" do
    assert_difference('TimePeriod.count') do
      post :create, :time_period => { }
    end

    assert_redirected_to time_period_path(assigns(:time_period))
  end

  test "should show time_period" do
    get :show, :id => time_periods(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => time_periods(:one).to_param
    assert_response :success
  end

  test "should update time_period" do
    put :update, :id => time_periods(:one).to_param, :time_period => { }
    assert_redirected_to time_period_path(assigns(:time_period))
  end

  test "should destroy time_period" do
    assert_difference('TimePeriod.count', -1) do
      delete :destroy, :id => time_periods(:one).to_param
    end

    assert_redirected_to time_periods_path
  end
end
