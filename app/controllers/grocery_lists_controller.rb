class GroceryListsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_preference

  def current
    @active_plan = current_patient.active_nutrition_plan
    @grocery_list = current_patient.grocery_lists
      .includes(grocery_list_items: :grocery_product_matches)
      .order(created_at: :desc)
      .first
    @retailer_options = SupermarketCatalogProvider.supported_retailers_for_select
  end

  def generate
    @preference.assign_attributes(preference_params)
    apply_retailer_metadata

    unless @preference.save
      load_current_state
      render :current, status: :unprocessable_entity
      return
    end

    @grocery_list = ShoppingListGeneratorService.new(
      patient: current_patient,
      date_from: parse_date(params[:date_from]),
      date_to: parse_date(params[:date_to])
    ).call

    redirect_to current_grocery_lists_path, notice: "Lista de compra generada."
  rescue ShoppingListGeneratorService::Error => e
    load_current_state
    flash.now[:alert] = e.message
    render :current, status: :unprocessable_entity
  end

  private

  def set_preference
    @preference = current_patient.user_supermarket_preference ||
      current_patient.build_user_supermarket_preference(
        SupermarketCatalogProvider.default_preference_attributes
      )
  end

  def load_current_state
    @active_plan = current_patient.active_nutrition_plan
    @grocery_list = current_patient.grocery_lists
      .includes(grocery_list_items: :grocery_product_matches)
      .order(created_at: :desc)
      .first
    @retailer_options = SupermarketCatalogProvider.supported_retailers_for_select
  end

  def parse_date(raw_value)
    return nil if raw_value.blank?

    Date.parse(raw_value)
  rescue ArgumentError
    nil
  end

  def preference_params
    params.require(:user_supermarket_preference).permit(
      :country_code, :currency, :retailer_slug, :retailer_name
    )
  end

  def apply_retailer_metadata
    return if @preference.retailer_slug.blank?

    @preference.country_code = SupermarketCatalogProvider.country_for(@preference.retailer_slug)
    @preference.currency = SupermarketCatalogProvider.currency_for(@preference.retailer_slug)
    @preference.retailer_name = SupermarketCatalogProvider.label_for(@preference.retailer_slug)
  end
end
