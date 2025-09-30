require "test_helper"

class NutritionistAiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get nutritionist_ai_messages_create_url
    assert_response :success
  end
end
