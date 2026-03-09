require "test_helper"

class NutritionistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient)
    @sibling_patient = patients(:owned_patient_sibling)
    @foreign_patient = patients(:foreign_patient)
  end

  test "dashboard only shows patients and plans owned by the signed in nutritionist" do
    sign_in @nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    refute_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
  end

  test "dashboard for other nutritionist excludes foreign collections" do
    sign_in @other_nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
    refute_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    refute_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
  end

  test "patient radar only shows current nutritionist patients" do
    sign_in @nutritionist

    get nutritionist_patient_radar_path

    assert_response :success
    assert_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    refute_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
  end

  test "patient radar for other nutritionist excludes foreign patients" do
    sign_in @other_nutritionist

    get nutritionist_patient_radar_path

    assert_response :success
    assert_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
    refute_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    refute_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
  end
end
