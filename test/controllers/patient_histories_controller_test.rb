require "test_helper"

class PatientHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient)
    @history = patient_histories(:owned_history)
    @plan = nutrition_plans(:owned_plan)
    @sibling_plan = nutrition_plans(:sibling_plan)
    @foreign_plan = nutrition_plans(:foreign_plan)
  end

  test "owner can access index show new and edit" do
    sign_in @nutritionist

    get patient_patient_histories_path(@patient)
    assert_response :success

    get patient_patient_history_path(@patient, @history)
    assert_response :success

    get new_patient_patient_history_path(@patient)
    assert_response :success

    get edit_patient_patient_history_path(@patient, @history)
    assert_response :success
  end

  test "owner can create patient history with a plan from the same patient" do
    sign_in @nutritionist

    assert_difference("PatientHistory.count", 1) do
      post patient_patient_histories_path(@patient), params: {
        patient_history: {
          visit_date: Date.current,
          notes: "Monthly review",
          weight: 70.1,
          metrics: "Stable",
          nutrition_plan_id: @plan.id
        }
      }
    end

    assert_redirected_to patient_patient_history_path(@patient, PatientHistory.order(:id).last)
  end

  test "owner cannot create patient history with a plan from another patient" do
    sign_in @nutritionist

    assert_no_difference("PatientHistory.count") do
      post patient_patient_histories_path(@patient), params: {
        patient_history: {
          visit_date: Date.current,
          notes: "Monthly review",
          weight: 70.1,
          metrics: "Stable",
          nutrition_plan_id: @sibling_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "owner cannot create patient history with a foreign nutritionist plan" do
    sign_in @nutritionist

    assert_no_difference("PatientHistory.count") do
      post patient_patient_histories_path(@patient), params: {
        patient_history: {
          visit_date: Date.current,
          notes: "Monthly review",
          weight: 70.1,
          metrics: "Stable",
          nutrition_plan_id: @foreign_plan.id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "owner can update and destroy owned patient history" do
    sign_in @nutritionist

    patch patient_patient_history_path(@patient, @history), params: {
      patient_history: {
        notes: "Updated follow-up",
        nutrition_plan_id: @plan.id
      }
    }
    assert_redirected_to patient_patient_history_path(@patient, @history)
    assert_equal "Updated follow-up", @history.reload.notes

    assert_difference("PatientHistory.count", -1) do
      delete patient_patient_history_path(@patient, @history)
    end

    assert_redirected_to patient_patient_histories_path(@patient)
  end

  test "owner cannot update patient history with a plan from another patient" do
    sign_in @nutritionist

    patch patient_patient_history_path(@patient, @history), params: {
      patient_history: {
        notes: "Attempted cross-patient link",
        nutrition_plan_id: @sibling_plan.id
      }
    }

    assert_response :unprocessable_entity
    assert_equal @plan.id, @history.reload.nutrition_plan_id
  end

  test "other nutritionist cannot access foreign patient history" do
    sign_in @other_nutritionist

    get patient_patient_history_path(@patient, @history)

    assert_response :not_found
  end
end
