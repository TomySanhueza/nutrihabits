class GroceryListItem < ApplicationRecord
  belongs_to :grocery_list
  has_many :grocery_product_matches, dependent: :destroy

  validates :ingredient_name, :normalized_name, presence: true
end
