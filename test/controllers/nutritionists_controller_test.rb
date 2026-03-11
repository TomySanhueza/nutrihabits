require "test_helper"

class NutritionistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @empty_nutritionist = nutritionists(:empty_owner)
    @patient = patients(:owned_patient)
    @sibling_patient = patients(:owned_patient_sibling)
    @patient_without_plan = patients(:owned_patient_without_plan)
    @patient_without_profile = patients(:owned_patient_without_profile)
    @foreign_patient = patients(:foreign_patient)
  end

  test "dashboard only shows patients and plans owned by the signed in nutritionist" do
    sign_in @nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    assert_includes response.body, "#{@patient_without_plan.first_name} #{@patient_without_plan.last_name}"
    assert_includes response.body, "#{@patient_without_profile.first_name} #{@patient_without_profile.last_name}"
    refute_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
    assert_includes response.body, "Resumen de pacientes"
    assert_includes response.body, "Planes recientes"
  end

  test "dashboard for other nutritionist excludes foreign collections" do
    sign_in @other_nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
    refute_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    refute_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    refute_includes response.body, "#{@patient_without_plan.first_name} #{@patient_without_plan.last_name}"
  end

  test "dashboard shows empty state when nutritionist has no patients" do
    sign_in @empty_nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "Aún no tienes pacientes creados."
    assert_includes response.body, "Crear primer paciente"
  end

  test "dashboard exposes correct ctas for missing profile and missing active plan" do
    sign_in @nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, new_patient_profile_path(@patient_without_profile)
    assert_includes response.body, "Completar perfil"
    assert_includes response.body, new_patient_nutrition_plan_path(@patient_without_plan)
    assert_includes response.body, "Preparar plan"
  end

  test "dashboard renders recent plans scoped and ordered" do
    sign_in @nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "Plan reciente Alice"
    assert_includes response.body, "Plan base Bob"
    refute_includes response.body, "Plan externo Charlie"
    assert_operator response.body.index(patient_nutrition_plan_path(@patient, nutrition_plans(:owned_plan))), :<,
      response.body.index(patient_nutrition_plan_path(@sibling_patient, nutrition_plans(:sibling_plan)))
  end

  test "dashboard shows radar teaser without embedding radar entries inline" do
    sign_in @nutritionist

    get nutritionist_dashboard_path

    assert_response :success
    assert_includes response.body, "Radar de pacientes"
    assert_includes response.body, nutritionist_patient_radar_path
    assert_includes response.body, "Task 3 pendiente"
  end

  test "patient radar only shows current nutritionist patients" do
    sign_in @nutritionist

    get nutritionist_patient_radar_path

    assert_response :success
    assert_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    assert_includes response.body, "#{@patient_without_plan.first_name} #{@patient_without_plan.last_name}"
    assert_includes response.body, "#{@patient_without_profile.first_name} #{@patient_without_profile.last_name}"
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
