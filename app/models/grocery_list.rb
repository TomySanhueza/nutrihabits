class GroceryList < ApplicationRecord
  belongs_to :patient
  belongs_to :nutrition_plan, optional: true
  has_many :grocery_list_items, dependent: :destroy

  validates :date_from, :date_to, :retailer_slug, :country_code, :currency, presence: true
end
