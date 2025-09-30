require "test_helper"

class MealLogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get meal_logs_index_url
    assert_response :success
  end

  test "should get create" do
    get meal_logs_create_url
    assert_response :success
  end

  test "should get destroy" do
    get meal_logs_destroy_url
    assert_response :success
  end
end
