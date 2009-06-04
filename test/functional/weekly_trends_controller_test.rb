require 'test_helper'

class WeeklyTrendsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:weekly_trends)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create weekly_trend" do
    assert_difference('WeeklyTrend.count') do
      post :create, :weekly_trend => { }
    end

    assert_redirected_to weekly_trend_path(assigns(:weekly_trend))
  end

  test "should show weekly_trend" do
    get :show, :id => weekly_trends(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => weekly_trends(:one).to_param
    assert_response :success
  end

  test "should update weekly_trend" do
    put :update, :id => weekly_trends(:one).to_param, :weekly_trend => { }
    assert_redirected_to weekly_trend_path(assigns(:weekly_trend))
  end

  test "should destroy weekly_trend" do
    assert_difference('WeeklyTrend.count', -1) do
      delete :destroy, :id => weekly_trends(:one).to_param
    end

    assert_redirected_to weekly_trends_path
  end
end
