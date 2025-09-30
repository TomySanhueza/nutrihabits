require "test_helper"

class PatientAiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get patient_ai_messages_create_url
    assert_response :success
  end
end
