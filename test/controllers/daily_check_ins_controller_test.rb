require "test_helper"

class DailyCheckInsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get daily_check_ins_index_url
    assert_response :success
  end

  test "should get create" do
    get daily_check_ins_create_url
    assert_response :success
  end
end
