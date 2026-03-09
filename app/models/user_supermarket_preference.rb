class UserSupermarketPreference < ApplicationRecord
  belongs_to :patient

  validates :country_code, presence: true
  validates :currency, presence: true
  validates :retailer_slug, presence: true
end
