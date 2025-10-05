module PatientMetrics
  class PatientSelfMetrics
    def initialize(patient_id)
      @patient = Patient.find(patient_id)
      @active_plan = @patient.nutrition_plans.find_by(status: 'active')
    end

    def my_progress(days = 30)
      ProgressAnalyzer.new(@patient.id).weight_evolution(days)
    end

    def todays_intake
      today_logs = @patient.meal_logs_through_plans.where('logged_at >= ?', Date.today.beginning_of_day)

      return { message: "Aún no has registrado comidas hoy" } if today_logs.empty?

      {
        date: Date.today,
        meals_logged: today_logs.count,
        total_calories: today_logs.sum(:ai_calories).round(1),
        total_protein: today_logs.sum(:ai_protein).round(1),
        total_carbs: today_logs.sum(:ai_carbs).round(1),
        total_fat: today_logs.sum(:ai_fat).round(1),
        average_health_score: today_logs.average(:ai_health_score).to_f.round(2),
        plan_target: @active_plan ? {
          calories: @active_plan.calories,
          protein: @active_plan.protein,
          carbs: @active_plan.carbs,
          fat: @active_plan.fat
        } : nil
      }
    end

    def todays_meals
      return { message: "No tienes un plan activo" } unless @active_plan

      today_plan = @active_plan.plans.find_by(date: Date.today)
      return { message: "No hay comidas planificadas para hoy" } unless today_plan

      {
        date: Date.today,
        meals: today_plan.meals.map do |meal|
          {
            id: meal.id,
            meal_type: meal.meal_type,
            ingredients: meal.ingredients,
            recipe: meal.recipe,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            status: meal.status,
            logged: meal.meal_log.present?
          }
        end
      }
    end

    def achievement_summary
      return { message: "No tienes un plan activo" } unless @active_plan

      total_meals = @active_plan.plans.joins(:meals).count
      completed_meals = @active_plan.plans.joins(:meals).where(meals: { status: 'completed' }).count

      meal_logs = @patient.meal_logs_through_plans.where('logged_at >= ?', @active_plan.start_date)

      days_with_logs = meal_logs.pluck(:logged_at).map(&:to_date).uniq.count
      consecutive_days = calculate_consecutive_days(meal_logs)

      {
        plan_start_date: @active_plan.start_date,
        days_on_plan: (Date.today - @active_plan.start_date).to_i,
        total_meals_planned: total_meals,
        meals_completed: completed_meals,
        adherence_percentage: total_meals > 0 ? (completed_meals.to_f / total_meals * 100).round(1) : 0,
        days_with_activity: days_with_logs,
        current_streak_days: consecutive_days,
        average_health_score: meal_logs.average(:ai_health_score).to_f.round(2)
      }
    end

    def shopping_list(days = 7)
      return { message: "No tienes un plan activo" } unless @active_plan

      upcoming_plans = @active_plan.plans.where('date >= ? AND date <= ?', Date.today, Date.today + days.days)

      all_ingredients = upcoming_plans.includes(:meals).map do |plan|
        plan.meals.map { |meal| { date: plan.date, meal_type: meal.meal_type, ingredients: meal.ingredients } }
      end.flatten

      {
        period: "#{Date.today.strftime('%d/%m')} - #{(Date.today + days.days).strftime('%d/%m')}",
        days: days,
        meals_count: all_ingredients.count,
        ingredients_by_day: all_ingredients.group_by { |m| m[:date] }
      }
    end

    def hydration_needs
      profile = @patient.profile
      return { message: "Necesitas completar tu perfil" } unless profile&.weight

      # Fórmula básica: 30-35 ml por kg de peso
      base_ml = profile.weight * 33
      liters = (base_ml / 1000.0).round(1)

      {
        weight_kg: profile.weight,
        daily_water_liters: liters,
        daily_water_ml: base_ml.round(0),
        glasses_8oz: (liters / 0.24).round(0),
        recommendation: "Bebe aproximadamente #{liters}L de agua al día, distribuyendo a lo largo del día"
      }
    end

    private

    def calculate_consecutive_days(meal_logs)
      dates = meal_logs.pluck(:logged_at).map(&:to_date).uniq.sort.reverse
      return 0 if dates.empty?

      consecutive = 1
      dates.each_cons(2) do |current, previous|
        break unless (previous - current).to_i == 1
        consecutive += 1
      end
      consecutive
    end
  end
end
