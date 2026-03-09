class MealLogAnalysisJob < ApplicationJob
  queue_as :default

  def perform(meal_log_id)
    meal_log = MealLog.find(meal_log_id)
    return unless meal_log.photo.attached?

    meal_log.update!(analysis_status: "processing", analysis_error: nil)

    analysis_result = MealLogAnalysisService.new(meal_log.photo, meal_log.meal).call

    meal_log.update!(
      ai_calories: analysis_result["ai_calories"],
      ai_protein: analysis_result["ai_protein"],
      ai_carbs: analysis_result["ai_carbs"],
      ai_fat: analysis_result["ai_fat"],
      ai_health_score: analysis_result["ai_health_score"],
      ai_feedback: analysis_result["ai_feedback"],
      ai_comparison: analysis_result["ai_comparison"],
      analysis_status: "completed",
      analysis_error: nil
    )
  rescue StandardError => e
    meal_log&.update(
      analysis_status: "failed",
      analysis_error: e.message.to_s.first(500)
    )
    Rails.logger.error("MealLogAnalysisJob failed for #{meal_log_id}: #{e.message}")
  end
end
