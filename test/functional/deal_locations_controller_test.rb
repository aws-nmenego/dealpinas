require 'test_helper'

class DealLocationsControllerTest < ActionController::TestCase
  setup do
    @deal_location = deal_locations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deal_locations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create deal_location" do
    assert_difference('DealLocation.count') do
      post :create, deal_location: @deal_location.attributes
    end

    assert_redirected_to deal_location_path(assigns(:deal_location))
  end

  test "should show deal_location" do
    get :show, id: @deal_location
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @deal_location
    assert_response :success
  end

  test "should update deal_location" do
    put :update, id: @deal_location, deal_location: @deal_location.attributes
    assert_redirected_to deal_location_path(assigns(:deal_location))
  end

  test "should destroy deal_location" do
    assert_difference('DealLocation.count', -1) do
      delete :destroy, id: @deal_location
    end

    assert_redirected_to deal_locations_path
  end
end
