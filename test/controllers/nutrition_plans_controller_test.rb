require "test_helper"

class NutritionPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nutritionist = nutritionists(:owner)
    @other_nutritionist = nutritionists(:other_owner)
    @patient = patients(:owned_patient)
    @sibling_patient = patients(:owned_patient_sibling)
    @plan = nutrition_plans(:owned_plan)
    @foreign_plan = nutrition_plans(:foreign_plan)
  end

  test "owner can access index and new" do
    sign_in @nutritionist

    get patient_nutrition_plans_path(@patient)
    assert_response :success

    get new_patient_nutrition_plan_path(@patient)
    assert_response :success
  end

  test "owner can show and edit an owned plan" do
    sign_in @nutritionist

    get patient_nutrition_plan_path(@patient, @plan)
    assert_response :success

    get edit_patient_nutrition_plan_path(@patient, @plan)
    assert_response :success
  end

  test "owner can create a nutrition plan for an owned patient" do
    sign_in @nutritionist

    response_payload = {
      "plan" => {
        "objective" => "Maintain energy",
        "calories" => 1900.0,
        "protein" => 110.0,
        "fat" => 60.0,
        "carbs" => 210.0,
        "meal_distribution" => {
          Date.current.to_s => {
            "breakfast" => {
              "ingredients" => "Oats and yogurt",
              "recipe" => "Mix and serve",
              "calorias" => 350.0,
              "protein" => 20.0,
              "carbs" => 45.0,
              "fat" => 10.0
            }
          }
        },
        "notes" => "Keep hydration high"
      },
      "criteria_explanation" => "Scoped test payload"
    }

    assert_difference("NutritionPlan.count", 1) do
      assert_difference("Plan.count", 1) do
        assert_difference("Meal.count", 1) do
          with_stubbed_plan_generator(response_payload) do
            post patient_nutrition_plans_path(@patient)
          end
        end
      end
    end

    created_plan = NutritionPlan.order(:id).last
    assert_redirected_to edit_patient_nutrition_plan_path(@patient, created_plan)
    assert_equal @patient.id, created_plan.patient_id
    assert_equal @nutritionist.id, created_plan.nutritionist_id
  end

  test "owner can update and destroy an owned plan" do
    sign_in @nutritionist
    destroyable_plan = NutritionPlan.create!(
      patient: @patient,
      nutritionist: @nutritionist,
      objective: "Destroyable plan",
      calories: 1700,
      protein: 100,
      fat: 55,
      carbs: 180,
      meal_distribution: {},
      status: "active",
      start_date: Date.current,
      end_date: Date.current + 6.days
    )

    patch patient_nutrition_plan_path(@patient, @plan), params: {
      nutrition_plan: {
        notes: "Updated notes"
      }
    }
    assert_redirected_to patient_nutrition_plan_path(@patient, @plan)
    assert_equal "Updated notes", @plan.reload.notes

    assert_difference("NutritionPlan.count", -1) do
      delete patient_nutrition_plan_path(@patient, destroyable_plan)
    end

    assert_redirected_to patient_nutrition_plans_path(@patient)
  end

  test "other nutritionist cannot create a plan for a foreign patient" do
    sign_in @other_nutritionist

    response_payload = {
      "plan" => {
        "objective" => "Blocked plan",
        "calories" => 1800.0,
        "protein" => 100.0,
        "fat" => 55.0,
        "carbs" => 200.0,
        "meal_distribution" => {
          Date.current.to_s => {
            "breakfast" => {
              "ingredients" => "Toast",
              "recipe" => "Serve",
              "calorias" => 250.0,
              "protein" => 10.0,
              "carbs" => 30.0,
              "fat" => 8.0
            }
          }
        },
        "notes" => "Should not be created"
      },
      "criteria_explanation" => "Cross-tenant request"
    }

    assert_no_difference("NutritionPlan.count") do
      assert_no_difference("Plan.count") do
        assert_no_difference("Meal.count") do
          with_stubbed_plan_generator(response_payload) do
            post patient_nutrition_plans_path(@patient)
          end
        end
      end
    end

    assert_response :not_found
  end

  test "other nutritionist cannot update or destroy a foreign plan" do
    sign_in @other_nutritionist

    assert_no_changes -> { @plan.reload.notes } do
      patch patient_nutrition_plan_path(@patient, @plan), params: {
        nutrition_plan: { notes: "Hijacked notes" }
      }
    end
    assert_response :not_found

    sign_in @other_nutritionist

    assert_no_difference("NutritionPlan.count") do
      delete patient_nutrition_plan_path(@patient, @plan)
    end
    assert_response :not_found
  end

  test "other nutritionist cannot access foreign patient plans" do
    sign_in @other_nutritionist

    get patient_nutrition_plans_path(@patient)

    assert_response :not_found
  end

  test "nested route does not resolve plan from another patient of same nutritionist" do
    sign_in @nutritionist

    get patient_nutrition_plan_path(@sibling_patient, @plan)

    assert_response :not_found
  end

  test "nested route cannot update or destroy a plan through another owned patient" do
    sign_in @nutritionist

    assert_no_changes -> { @plan.reload.notes } do
      patch patient_nutrition_plan_path(@sibling_patient, @plan), params: {
        nutrition_plan: { notes: "Wrong nested route" }
      }
    end
    assert_response :not_found

    sign_in @nutritionist

    assert_no_difference("NutritionPlan.count") do
      delete patient_nutrition_plan_path(@sibling_patient, @plan)
    end
    assert_response :not_found
  end

  test "foreign nutritionist plan is not accessible through current nutritionist patient route" do
    sign_in @nutritionist

    get patient_nutrition_plan_path(@patient, @foreign_plan)
    assert_response :not_found

    sign_in @nutritionist

    assert_no_changes -> { @foreign_plan.reload.notes } do
      patch patient_nutrition_plan_path(@patient, @foreign_plan), params: {
        nutrition_plan: { notes: "Should stay foreign" }
      }
    end
    assert_response :not_found
  end

  private

  def with_stubbed_plan_generator(response_payload)
    fake_service = Struct.new(:call).new(response_payload)
    singleton = NutritionPlanGeneratorService.singleton_class

    singleton.send(:alias_method, :__codex_original_new, :new)
    singleton.send(:define_method, :new) do |*_args|
      fake_service
    end

    yield
  ensure
    if singleton.method_defined?(:__codex_original_new)
      singleton.send(:remove_method, :new)
      singleton.send(:alias_method, :new, :__codex_original_new)
      singleton.send(:remove_method, :__codex_original_new)
    end
  end
end
