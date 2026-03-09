class ShoppingListGeneratorService
  class Error < StandardError; end

  INGREDIENT_PATTERN = /\A(?:(?<quantity>\d+(?:[.,]\d+)?)\s*)?(?<unit>kg|g|ml|l|unidad(?:es)?|u|taza(?:s)?|cucharada(?:s)?|cucharadita(?:s)?)?\s*(?:de\s+)?(?<name>.+)\z/i

  def initialize(patient:, date_from: nil, date_to: nil)
    @patient = patient
    @preference = patient.user_supermarket_preference || patient.build_user_supermarket_preference(
      SupermarketCatalogProvider.default_preference_attributes
    )
    @date_from = date_from
    @date_to = date_to
  end

  def call
    plan = @patient.active_nutrition_plan
    raise Error, "No hay un plan activo para generar la compra." unless plan

    date_from = @date_from || [Date.current, plan.start_date].compact.max
    date_to = @date_to || [date_from + 6.days, plan.end_date].compact.min

    meals = plan.plans.includes(:meals).where(date: date_from..date_to).flat_map(&:meals)
    raise Error, "No hay comidas planificadas en el rango solicitado." if meals.empty?

    provider = SupermarketCatalogProvider.for(preference: persisted_preference)
    grouped_items = aggregate_ingredients(meals)

    GroceryList.transaction do
      grocery_list = @patient.grocery_lists.create!(
        nutrition_plan: plan,
        date_from: date_from,
        date_to: date_to,
        retailer_slug: persisted_preference.retailer_slug,
        country_code: persisted_preference.country_code,
        currency: persisted_preference.currency,
        generated_by: "patient",
        status: "generated",
        source_summary: {
          nutrition_plan_id: plan.id,
          meal_count: meals.size
        }
      )

      grouped_items.each_value do |item_data|
        grocery_item = grocery_list.grocery_list_items.create!(
          ingredient_name: item_data[:ingredient_name],
          normalized_name: item_data[:normalized_name],
          quantity_value: item_data[:quantity_value],
          quantity_unit: item_data[:quantity_unit],
          meal_types: item_data[:meal_types].uniq,
          source_dates: item_data[:source_dates].uniq
        )

        provider.search(item_data[:normalized_name]).each_with_index do |product, index|
          grocery_item.grocery_product_matches.create!(
            external_id: product.external_id,
            retailer_slug: product.retailer_slug,
            country_code: product.country_code,
            name: product.name,
            brand: product.brand,
            package_size: product.package_size,
            price: product.price,
            currency: product.currency,
            availability: product.availability,
            product_url: product.url,
            rank: index + 1,
            metadata: {}
          )
        end
      end

      grocery_list
    end
  end

  private

  def persisted_preference
    @persisted_preference ||= begin
      @preference.save! unless @preference.persisted?
      @preference
    end
  end

  def aggregate_ingredients(meals)
    meals.each_with_object({}) do |meal, result|
      meal.ingredients.to_s.split(",").each do |raw_ingredient|
        parsed = parse_ingredient(raw_ingredient)
        key = [parsed[:normalized_name], parsed[:quantity_unit]].join(":")

        result[key] ||= {
          ingredient_name: parsed[:ingredient_name],
          normalized_name: parsed[:normalized_name],
          quantity_value: 0.0,
          quantity_unit: parsed[:quantity_unit],
          meal_types: [],
          source_dates: []
        }

        result[key][:quantity_value] += parsed[:quantity_value]
        result[key][:meal_types] << meal.meal_type
        result[key][:source_dates] << meal.plan.date
      end
    end
  end

  def parse_ingredient(raw_ingredient)
    raw_text = raw_ingredient.to_s.strip
    match = INGREDIENT_PATTERN.match(raw_text)

    ingredient_name = match&.[](:name).presence || raw_text
    quantity_value = (match&.[](:quantity) || "1").tr(",", ".").to_f
    quantity_unit = (match&.[](:unit).presence || "unit").downcase

    {
      ingredient_name: raw_text,
      normalized_name: normalize(ingredient_name),
      quantity_value: quantity_value.zero? ? 1.0 : quantity_value,
      quantity_unit: quantity_unit
    }
  end

  def normalize(value)
    ActiveSupport::Inflector.transliterate(value.to_s)
      .downcase
      .gsub(/[^a-z0-9\s]/, " ")
      .squeeze(" ")
      .strip
  end
end
