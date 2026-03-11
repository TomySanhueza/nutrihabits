require "application_system_test_case"

class PatientShowSmokeTest < ApplicationSystemTestCase
  test "nutritionist can review patient summary plans and weight states" do
    nutritionist = nutritionists(:owner)
    patient = patients(:owned_patient)
    patient_without_profile = patients(:owned_patient_without_profile)
    active_plan = nutrition_plans(:owned_plan)

    visit new_nutritionist_session_path
    fill_in "nutritionist_email", with: nutritionist.email
    fill_in "nutritionist_password", with: "password123"
    click_button "Iniciar sesión"
    assert_current_path nutritionist_dashboard_path

    visit patient_path(patient)
    assert_text "#{patient.first_name} #{patient.last_name}"
    assert_text "Plan reciente Alice"
    assert_text "Plan previo Alice"
    assert_text "69.8 kg"
    assert_selector "a[href='#{patient_nutrition_plan_path(patient, active_plan)}']", text: "Ver detalle"
    assert_selector "a[href='#weights']", text: "Peso"

    visit patient_path(patient_without_profile)
    assert_text "Perfil pendiente"
    assert_text "Sin plan activo"
    assert_selector "a[href='#{new_patient_profile_path(patient_without_profile)}']", text: "Completar perfil"
  end
end
