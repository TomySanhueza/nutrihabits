require "application_system_test_case"

class NutritionistDashboardSmokeTest < ApplicationSystemTestCase
  test "nutritionist can review dashboard, patient, plan and radar" do
    nutritionist = nutritionists(:owner)
    patient = patients(:owned_patient)
    plan = nutrition_plans(:owned_plan)

    visit new_nutritionist_session_path
    fill_in "nutritionist_email", with: nutritionist.email
    fill_in "nutritionist_password", with: "password123"
    click_button "Iniciar sesión"

    assert_current_path nutritionist_dashboard_path
    assert_text "Resumen de pacientes"
    assert_selector "#patient-summary-list article", minimum: 1
    assert_selector "#recent-plans-list article", minimum: 1

    within "#patient-summary-list" do
      within find("article", text: "#{patient.first_name} #{patient.last_name}") do
        assert_selector "a[href='#{patient_path(patient)}']", text: "Ver paciente"
      end
    end
    visit patient_path(patient)
    assert_text "#{patient.first_name} #{patient.last_name}"

    visit patients_path
    assert_text "Cartera de pacientes"
    assert_selector "table"
    assert_selector "a[href='#{patient_nutrition_plans_path(patient)}']", text: "Ver planes"

    visit patient_nutrition_plans_path(patient)
    assert_text "Listado de planes"
    assert_selector "a[href='#{new_patient_nutrition_plan_path(patient)}']", text: "Preparar plan"

    visit nutritionist_dashboard_path
    within "#recent-plans-list" do
      within find("article", text: plan.objective) do
        assert_selector "a[href='#{patient_nutrition_plan_path(patient, plan)}']", text: "Ver detalle"
      end
    end
    visit patient_nutrition_plan_path(patient, plan)
    assert_text plan.objective
    assert_text "Distribución de comidas"

    visit new_patient_nutrition_plan_path(patient)
    assert_text "Nuevo plan para #{patient.first_name} #{patient.last_name}"
    assert_button "Generar borrador con IA"

    visit edit_patient_nutrition_plan_path(patient, plan)
    assert_text "Planes diarios"
    assert_button "Guardar plan"

    visit nutritionist_dashboard_path
    radar_link = find("a", text: "Abrir radar")
    execute_script("arguments[0].click();", radar_link)
    assert_current_path nutritionist_patient_radar_path
    assert_text "Radar de Pacientes"
  end
end
