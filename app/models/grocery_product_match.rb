class GroceryProductMatch < ApplicationRecord
  belongs_to :grocery_list_item

  validates :name, :retailer_slug, :country_code, presence: true
end
