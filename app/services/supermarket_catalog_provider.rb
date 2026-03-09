class SupermarketCatalogProvider
  Product = Struct.new(
    :external_id,
    :name,
    :brand,
    :package_size,
    :price,
    :currency,
    :availability,
    :url,
    :retailer_slug,
    :country_code,
    keyword_init: true
  )

  SUPPORTED_RETAILERS = [
    ["Jumbo Chile", "jumbo-cl", "CL", "CLP"],
    ["Mercadona España", "mercadona-es", "ES", "EUR"]
  ].freeze

  def self.default_preference_attributes
    {
      country_code: "CL",
      currency: "CLP",
      retailer_slug: "jumbo-cl",
      retailer_name: "Jumbo Chile"
    }
  end

  def self.supported_retailers_for_select
    SUPPORTED_RETAILERS.map { |label, slug, _country, _currency| [label, slug] }
  end

  def self.metadata_for(retailer_slug)
    SUPPORTED_RETAILERS.find { |_label, slug, _country, _currency| slug == retailer_slug }
  end

  def self.country_for(retailer_slug)
    metadata_for(retailer_slug)&.[](2) || "CL"
  end

  def self.currency_for(retailer_slug)
    metadata_for(retailer_slug)&.[](3) || "CLP"
  end

  def self.label_for(retailer_slug)
    metadata_for(retailer_slug)&.[](0) || retailer_slug.to_s.humanize
  end

  def self.for(preference:)
    SupermarketCatalogProviders::FeedCatalogProvider.new(
      retailer_slug: preference.retailer_slug,
      country_code: preference.country_code.presence || country_for(preference.retailer_slug),
      currency: preference.currency.presence || currency_for(preference.retailer_slug)
    )
  end
end
