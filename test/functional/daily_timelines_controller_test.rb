require 'test_helper'

class DailyTimelinesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:daily_timelines)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create daily_timeline" do
    assert_difference('DailyTimeline.count') do
      post :create, :daily_timeline => { }
    end

    assert_redirected_to daily_timeline_path(assigns(:daily_timeline))
  end

  test "should show daily_timeline" do
    get :show, :id => daily_timelines(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => daily_timelines(:one).to_param
    assert_response :success
  end

  test "should update daily_timeline" do
    put :update, :id => daily_timelines(:one).to_param, :daily_timeline => { }
    assert_redirected_to daily_timeline_path(assigns(:daily_timeline))
  end

  test "should destroy daily_timeline" do
    assert_difference('DailyTimeline.count', -1) do
      delete :destroy, :id => daily_timelines(:one).to_param
    end

    assert_redirected_to daily_timelines_path
  end
end
