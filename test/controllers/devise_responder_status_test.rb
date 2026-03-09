require "test_helper"

class DeviseResponderStatusTest < ActionDispatch::IntegrationTest
  setup do
    @patient = patients(:owned_patient)
    @nutritionist = nutritionists(:owner)
  end

  test "patient invalid sign in responds with unprocessable content" do
    post patient_session_path, params: {
      patient: {
        email: @patient.email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_content
    assert_select "h2", text: "Iniciar sesión"
    assert_match "Correo electr", response.body
  end

  test "nutritionist invalid sign in responds with unprocessable content" do
    post nutritionist_session_path, params: {
      nutritionist: {
        email: @nutritionist.email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_content
    assert_select "h2", text: "Iniciar sesión"
    assert_match "Contrase", response.body
  end

  test "nutritionist invalid sign up responds with unprocessable content" do
    assert_no_difference("Nutritionist.count") do
      post nutritionist_registration_path, params: {
        nutritionist: {
          email: @nutritionist.email,
          password: "short",
          password_confirmation: "mismatch",
          first_name: "",
          last_name: ""
        }
      }
    end

    assert_response :unprocessable_content
    assert_select "input[name='nutritionist[email]']"
  end
end
