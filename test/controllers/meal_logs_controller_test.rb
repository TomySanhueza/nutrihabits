require "test_helper"

class MealLogsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs

    @patient = patients(:owned_patient)
    @owned_breakfast = meals(:owned_breakfast)
    @owned_lunch = meals(:owned_lunch)
    @sibling_dinner = meals(:sibling_dinner)
    @foreign_snack = meals(:foreign_snack)
    @owned_breakfast_log = meal_logs(:owned_breakfast_log)
    @sibling_dinner_log = meal_logs(:sibling_dinner_log)
    @foreign_snack_log = meal_logs(:foreign_snack_log)
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "top-level index shows only current patient meal logs" do
    sign_in @patient

    get meal_logs_path

    assert_response :success
    assert_select "h5.card-title", text: "Breakfast"
    assert_select "h5.card-title", text: "Dinner", count: 0
    assert_select "h5.card-title", text: "Snack", count: 0
  end

  test "patient can access new show create and destroy for owned meal logs" do
    sign_in @patient

    get new_meal_meal_log_path(@owned_lunch)
    assert_response :success

    get meal_meal_log_path(@owned_breakfast, @owned_breakfast_log)
    assert_response :success

    assert_difference("MealLog.count", 1) do
      assert_enqueued_with(job: MealLogAnalysisJob) do
        post meal_meal_logs_path(@owned_lunch), params: {
          meal_log: {
            photo: uploaded_photo
          }
        }
      end
    end

    created_log = @owned_lunch.reload.meal_log
    assert_redirected_to meal_meal_log_path(@owned_lunch, created_log)
    assert_not_nil created_log.logged_at
    assert_equal @owned_lunch.meal_type, created_log.meal_type
    assert_equal "queued", created_log.analysis_status
    assert created_log.photo.attached?

    assert_difference("MealLog.count", -1) do
      delete meal_meal_log_path(@owned_breakfast, @owned_breakfast_log)
    end

    assert_redirected_to pats_dashboard_path
  end

  test "create without photo returns unprocessable entity and does not enqueue analysis" do
    sign_in @patient

    assert_no_difference("MealLog.count") do
      assert_no_enqueued_jobs only: MealLogAnalysisJob do
        post meal_meal_logs_path(@owned_lunch), params: {
          meal_log: {
            photo: nil
          }
        }
      end
    end

    assert_response :unprocessable_content
  end

  test "patient cannot access new meal log form for another patients meal" do
    sign_in @patient

    get new_meal_meal_log_path(@sibling_dinner)
    assert_response :not_found
  end

  test "patient cannot create a meal log for another patients meal" do
    sign_in @patient

    assert_no_difference("MealLog.count") do
      post meal_meal_logs_path(@foreign_snack), params: {
        meal_log: {
          photo: uploaded_photo
        }
      }
    end
    assert_response :not_found
  end

  test "patient cannot show another patients meal log" do
    sign_in @patient

    get meal_meal_log_path(@foreign_snack, @foreign_snack_log)
    assert_response :not_found
  end

  test "patient cannot destroy another patients meal log" do
    sign_in @patient

    assert_no_difference("MealLog.count") do
      delete meal_meal_log_path(@sibling_dinner, @sibling_dinner_log)
    end
    assert_response :not_found
  end

  test "show requires the meal and meal log to match" do
    sign_in @patient

    get meal_meal_log_path(@owned_lunch, @owned_breakfast_log)
    assert_response :not_found
  end

  test "destroy requires the meal and meal log to match" do
    sign_in @patient

    assert_no_difference("MealLog.count") do
      delete meal_meal_log_path(@owned_lunch, @owned_breakfast_log)
    end

    assert_response :not_found
  end

  test "route regression keeps meal log history top-level only" do
    sign_in @patient

    get meal_logs_path
    assert_response :success

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/meals/#{@owned_breakfast.id}/meal_logs", method: :get)
    end
  end

  private

  def uploaded_photo
    Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/meal-photo.jpg"),
      "image/jpeg"
    )
  end
end
