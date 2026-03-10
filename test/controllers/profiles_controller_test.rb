require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient_sibling)
    @patient_with_profile = patients(:owned_patient)
  end

  test "owner can access new profile form" do
    sign_in @nutritionist

    get new_patient_profile_path(@patient)

    assert_response :success
  end

  test "owner can create a profile for owned patient" do
    sign_in @nutritionist

    assert_difference("Profile.count", 1) do
      post patient_profiles_path(@patient), params: {
        profile: {
          weight: 68.5,
          height: 170,
          goals: "Improve adherence",
          conditions: "None",
          lifestyle: "Active",
          diagnosis: "Balanced nutrition"
        }
      }
    end

    assert_redirected_to patient_path(@patient)
    profile = Profile.order(:id).last
    assert_equal @patient.id, profile.patient_id
    assert_equal @nutritionist, profile.nutritionist
  end

  test "other nutritionist cannot access new profile form" do
    sign_in @other_nutritionist

    get new_patient_profile_path(@patient)

    assert_response :not_found
  end

  test "other nutritionist cannot create a profile for foreign patient" do
    sign_in @other_nutritionist

    assert_no_difference("Profile.count") do
      post patient_profiles_path(@patient), params: {
        profile: {
          weight: 68.5,
          height: 170,
          goals: "Improve adherence",
          conditions: "None",
          lifestyle: "Active",
          diagnosis: "Balanced nutrition"
        }
      }
    end

    assert_response :not_found
    assert_nil @patient.reload.profile
  end

  test "owner cannot create a second profile for the same patient" do
    sign_in @nutritionist

    assert_no_difference("Profile.count") do
      post patient_profiles_path(@patient_with_profile), params: {
        profile: {
          weight: 72.0,
          height: 176,
          goals: "Maintain",
          conditions: "None",
          lifestyle: "Active",
          diagnosis: "Stable"
        }
      }
    end

    assert_response :unprocessable_content
  end
end
