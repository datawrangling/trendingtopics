require 'test_helper'

class DailyTrendsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:daily_trends)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create daily_trend" do
    assert_difference('DailyTrend.count') do
      post :create, :daily_trend => { }
    end

    assert_redirected_to daily_trend_path(assigns(:daily_trend))
  end

  test "should show daily_trend" do
    get :show, :id => daily_trends(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => daily_trends(:one).to_param
    assert_response :success
  end

  test "should update daily_trend" do
    put :update, :id => daily_trends(:one).to_param, :daily_trend => { }
    assert_redirected_to daily_trend_path(assigns(:daily_trend))
  end

  test "should destroy daily_trend" do
    assert_difference('DailyTrend.count', -1) do
      delete :destroy, :id => daily_trends(:one).to_param
    end

    assert_redirected_to daily_trends_path
  end
end
