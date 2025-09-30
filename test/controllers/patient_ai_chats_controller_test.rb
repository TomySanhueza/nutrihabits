require "test_helper"

class PatientAiChatsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get patient_ai_chats_index_url
    assert_response :success
  end

  test "should get show" do
    get patient_ai_chats_show_url
    assert_response :success
  end

  test "should get create" do
    get patient_ai_chats_create_url
    assert_response :success
  end
end
