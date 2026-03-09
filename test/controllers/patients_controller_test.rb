require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient)
    @sibling_patient = patients(:owned_patient_sibling)
    @foreign_patient = patients(:foreign_patient)
  end

  test "index only lists patients owned by the signed in nutritionist" do
    sign_in @nutritionist

    get patients_path

    assert_response :success
    assert_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    refute_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
  end

  test "index for other nutritionist excludes patients owned by someone else" do
    sign_in @other_nutritionist

    get patients_path

    assert_response :success
    assert_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
    refute_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    refute_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
  end

  test "owner can see patient" do
    sign_in @nutritionist

    get patient_path(@patient)

    assert_response :success
  end

  test "other nutritionist cannot see patient" do
    sign_in @other_nutritionist

    get patient_path(@patient)

    assert_response :not_found
  end

  test "other nutritionist cannot invite patient" do
    sign_in @other_nutritionist

    assert_no_changes -> { @patient.reload.invitation_sent_at } do
      post invite_patient_path(@patient)
    end

    assert_response :not_found
  end

  test "other nutritionist cannot resend patient invite" do
    sign_in @other_nutritionist

    assert_no_changes -> { @patient.reload.invitation_sent_at } do
      post resend_invite_patient_path(@patient)
    end

    assert_response :not_found
  end

  test "other nutritionist cannot suspend patient access" do
    sign_in @other_nutritionist

    assert_no_changes -> { [ @patient.reload.onboarding_state, @patient.reload.access_suspended_at ] } do
      post suspend_access_patient_path(@patient)
    end

    assert_response :not_found
  end

  test "other nutritionist cannot reactivate patient access" do
    sign_in @other_nutritionist

    assert_no_changes -> { [ @patient.reload.onboarding_state, @patient.reload.access_suspended_at ] } do
      post reactivate_access_patient_path(@patient)
    end

    assert_response :not_found
  end
end
