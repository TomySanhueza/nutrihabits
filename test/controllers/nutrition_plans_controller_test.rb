require "test_helper"

class NutritionPlansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get nutrition_plans_index_url
    assert_response :success
  end

  test "should get show" do
    get nutrition_plans_show_url
    assert_response :success
  end

  test "should get create" do
    get nutrition_plans_create_url
    assert_response :success
  end

  test "should get update" do
    get nutrition_plans_update_url
    assert_response :success
  end

  test "should get destroy" do
    get nutrition_plans_destroy_url
    assert_response :success
  end
end
