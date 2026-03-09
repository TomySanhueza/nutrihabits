require "test_helper"

class MealsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @patient = patients(:owned_patient)
    @owned_breakfast = meals(:owned_breakfast)
    @owned_lunch = meals(:owned_lunch)
    @sibling_dinner = meals(:sibling_dinner)
    @foreign_snack = meals(:foreign_snack)
    @owned_plan_day = plans(:owned_plan_day)
    @sibling_plan_day = plans(:sibling_plan_day)
  end

  test "patient can access owned meals index show and edit" do
    sign_in @patient

    get meals_path
    assert_response :success
    assert_select "td", text: "Breakfast"
    assert_select "td", text: "Lunch"
    assert_select "td", text: "Dinner", count: 0
    assert_select "td", text: "Snack", count: 0

    get meal_path(@owned_breakfast)
    assert_response :success

    get edit_meal_path(@owned_breakfast)
    assert_response :success
  end

  test "patient can create update and destroy an owned meal" do
    sign_in @patient

    assert_difference("Meal.count", 1) do
      post meals_path, params: {
        meal: {
          plan_id: @owned_plan_day.id,
          meal_type: "snack",
          ingredients: "Apple and almonds",
          recipe: "Prepare and eat",
          calories: 260,
          protein: 8,
          carbs: 28,
          fat: 12,
          status: "pending"
        }
      }
    end

    created_meal = Meal.order(:id).last
    assert_redirected_to meal_path(created_meal)
    assert_equal @patient.id, created_meal.plan.nutrition_plan.patient_id

    patch meal_path(@owned_lunch), params: {
      meal: {
        calories: 650,
        status: "logged"
      }
    }

    assert_redirected_to meal_path(@owned_lunch)
    assert_equal 650, @owned_lunch.reload.calories
    assert_equal "logged", @owned_lunch.reload.status

    assert_difference("Meal.count", -1) do
      delete meal_path(created_meal)
    end

    assert_redirected_to meals_path
  end

  test "patient cannot show another patients meal" do
    sign_in @patient

    get meal_path(@sibling_dinner)
    assert_response :not_found
  end

  test "patient cannot edit another patients meal" do
    sign_in @patient

    get edit_meal_path(@foreign_snack)
    assert_response :not_found
  end

  test "patient cannot update another patients meal" do
    sign_in @patient

    assert_no_changes -> { @sibling_dinner.reload.status } do
      patch meal_path(@sibling_dinner), params: {
        meal: {
          status: "logged"
        }
      }
    end
    assert_response :not_found
  end

  test "patient cannot destroy another patients meal" do
    sign_in @patient

    assert_no_difference("Meal.count") do
      delete meal_path(@foreign_snack)
    end
    assert_response :not_found
  end

  test "patient cannot create or move meals using another patients plans" do
    sign_in @patient

    assert_no_difference("Meal.count") do
      post meals_path, params: {
        meal: {
          plan_id: @sibling_plan_day.id,
          meal_type: "snack",
          ingredients: "Forbidden plan",
          recipe: "Should not persist",
          calories: 150,
          protein: 5,
          carbs: 15,
          fat: 5,
          status: "pending"
        }
      }
    end
    assert_response :unprocessable_content

    assert_no_changes -> { @owned_lunch.reload.plan_id } do
      patch meal_path(@owned_lunch), params: {
        meal: {
          plan_id: @sibling_plan_day.id
        }
      }
    end
    assert_response :unprocessable_content
  end
end
