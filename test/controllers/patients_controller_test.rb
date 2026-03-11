require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient)
    @sibling_patient = patients(:owned_patient_sibling)
    @patient_without_plan = patients(:owned_patient_without_plan)
    @patient_without_profile = patients(:owned_patient_without_profile)
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

  test "index can filter owned patients by search" do
    sign_in @nutritionist

    get patients_path(search: @sibling_patient.first_name)

    assert_response :success
    assert_includes response.body, "#{@sibling_patient.first_name} #{@sibling_patient.last_name}"
    refute_includes response.body, "#{@patient.first_name} #{@patient.last_name}"
    refute_includes response.body, "#{@foreign_patient.first_name} #{@foreign_patient.last_name}"
  end

  test "owner can see patient with real plan and weight history" do
    sign_in @nutritionist

    get patient_path(@patient)

    assert_response :success
    assert_includes response.body, "Plan reciente Alice"
    assert_includes response.body, "Plan previo Alice"
    assert_includes response.body, "69.8 kg"
    assert_includes response.body, "Acceso app: Activo"
    assert_includes response.body, "Control clínico"
    refute_includes response.body, "70.4 kg"
  end

  test "show handles patient histories without weight entries or profile" do
    sign_in @nutritionist

    get patient_path(@sibling_patient)

    assert_response :success
    assert_includes response.body, "72 kg"
    assert_includes response.body, "Sin dato"
    assert_includes response.body, "Plan base Bob"
  end

  test "show renders empty states for patient without profile plan or weights" do
    sign_in @nutritionist

    get patient_path(@patient_without_profile)

    assert_response :success
    assert_includes response.body, "Perfil pendiente"
    assert_includes response.body, "Sin plan activo"
    assert_includes response.body, "Aún no hay registros de peso"
    assert_includes response.body, "Acceso app: Invitado"
    assert_includes response.body, new_patient_profile_path(@patient_without_profile)
  end

  test "show falls back to profile weight when there is no timeline data" do
    fallback_patient = Patient.create!(
      nutritionist: @nutritionist,
      email: "fallback-patient@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Fiona",
      last_name: "Fallback",
      phone: "5556100",
      onboarding_state: "draft"
    )
    fallback_patient.create_profile!(
      weight: 77.4,
      height: 181,
      goals: "Recover routine",
      conditions: "None",
      lifestyle: "Office work",
      diagnosis: "Needs baseline"
    )

    sign_in @nutritionist

    get patient_path(fallback_patient)

    assert_response :success
    assert_includes response.body, "77.4 kg"
    assert_includes response.body, "Fallback desde perfil clínico"
    assert_includes response.body, "Acceso app: Borrador"
  end

  test "show keeps history visible when patient has no active plan" do
    @patient_without_plan.update!(
      onboarding_state: "suspended",
      access_suspended_at: Time.current
    )

    sign_in @nutritionist

    get patient_path(@patient_without_plan)

    assert_response :success
    assert_includes response.body, "Sin plan activo"
    assert_includes response.body, "Plan cerrado Diana"
    assert_includes response.body, "68.2 kg"
    assert_includes response.body, "Acceso app: Suspendido"
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
