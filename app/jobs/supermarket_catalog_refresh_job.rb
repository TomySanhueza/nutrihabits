class SupermarketCatalogRefreshJob < ApplicationJob
  queue_as :default

  def perform(retailer_slug = nil)
    Rails.logger.info("Supermarket catalog refresh requested for #{retailer_slug || 'all retailers'}")
  end
end
