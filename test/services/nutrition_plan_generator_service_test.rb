require "test_helper"

class NutritionPlanGeneratorServiceTest < ActiveSupport::TestCase
  setup do
    @patient = patients(:owned_patient)
    @nutritionist = nutritionists(:owner)
    @start_date = Date.current
    @end_date = Date.current + 1.day
  end

  test "creates nutrition plan, plans and meals from markdown wrapped json" do
    payload = wrapped_payload(valid_payload)

    assert_difference("NutritionPlan.count", 1) do
      assert_difference("Plan.count", 2) do
        assert_difference("Meal.count", 4) do
          nutrition_plan = build_service(payload).call

          assert_equal @patient, nutrition_plan.patient
          assert_equal @nutritionist, nutrition_plan.nutritionist
          assert_equal 2, nutrition_plan.plans.count
          assert_equal %w[breakfast snack], nutrition_plan.plans.order(:date).first.meals.order(:meal_type).pluck(:meal_type)
        end
      end
    end
  end

  test "raises generation error and leaves no partial records when payload is incomplete" do
    invalid_payload = valid_payload
    invalid_payload["plan"]["meal_distribution"].delete(@end_date.to_s)

    assert_no_difference("NutritionPlan.count") do
      assert_no_difference("Plan.count") do
        assert_no_difference("Meal.count") do
          error = assert_raises(NutritionPlanGeneratorService::GenerationError) do
            build_service(JSON.generate(invalid_payload)).call
          end

          assert_match(/missing dates/i, error.message)
        end
      end
    end
  end

  test "wraps llm client errors in generation error without persisting records" do
    chat = Class.new do
      def ask(_prompt)
        raise Timeout::Error, "llm timeout"
      end
    end.new

    assert_no_difference("NutritionPlan.count") do
      error = assert_raises(NutritionPlanGeneratorService::GenerationError) do
        NutritionPlanGeneratorService.new(
          patient: @patient,
          nutritionist: @nutritionist,
          start_date: @start_date,
          end_date: @end_date,
          chat: chat
        ).call
      end

      assert_match(/llm timeout/i, error.message)
    end
  end

  private

  def build_service(payload)
    NutritionPlanGeneratorService.new(
      patient: @patient,
      nutritionist: @nutritionist,
      start_date: @start_date,
      end_date: @end_date,
      chat: fake_chat(payload)
    )
  end

  def fake_chat(payload)
    Class.new do
      define_method(:initialize) { |response| @response = response }

      define_method(:ask) do |_prompt|
        Struct.new(:content).new(@response)
      end
    end.new(payload)
  end

  def wrapped_payload(payload)
    "```json\n#{JSON.generate(payload)}\n```"
  end

  def valid_payload
    {
      "plan" => {
        "objective" => "Maintain energy",
        "calories" => 1900.0,
        "protein" => 110.0,
        "fat" => 60.0,
        "carbs" => 210.0,
        "meal_distribution" => {
          @start_date.to_s => {
            "breakfast" => meal_data("Yogurt and oats", 350.0, 20.0, 45.0, 10.0),
            "snacks" => meal_data("Fruit and nuts", 220.0, 8.0, 24.0, 9.0)
          },
          @end_date.to_s => {
            "breakfast" => meal_data("Eggs and toast", 360.0, 22.0, 28.0, 14.0),
            "snacks" => meal_data("Kefir and berries", 180.0, 12.0, 18.0, 5.0)
          }
        },
        "notes" => "Keep hydration high"
      },
      "criteria_explanation" => "Scoped test payload"
    }
  end

  def meal_data(ingredients, calories, protein, carbs, fat)
    {
      "ingredients" => ingredients,
      "recipe" => "Mix and serve",
      "calorias" => calories,
      "protein" => protein,
      "carbs" => carbs,
      "fat" => fat
    }
  end
end
