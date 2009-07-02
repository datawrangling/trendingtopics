require 'test_helper'

class HourlyTimelinesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:hourly_timelines)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create hourly_timeline" do
    assert_difference('HourlyTimeline.count') do
      post :create, :hourly_timeline => { }
    end

    assert_redirected_to hourly_timeline_path(assigns(:hourly_timeline))
  end

  test "should show hourly_timeline" do
    get :show, :id => hourly_timelines(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => hourly_timelines(:one).to_param
    assert_response :success
  end

  test "should update hourly_timeline" do
    put :update, :id => hourly_timelines(:one).to_param, :hourly_timeline => { }
    assert_redirected_to hourly_timeline_path(assigns(:hourly_timeline))
  end

  test "should destroy hourly_timeline" do
    assert_difference('HourlyTimeline.count', -1) do
      delete :destroy, :id => hourly_timelines(:one).to_param
    end

    assert_redirected_to hourly_timelines_path
  end
end
