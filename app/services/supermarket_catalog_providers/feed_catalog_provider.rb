module SupermarketCatalogProviders
  class FeedCatalogProvider
    def initialize(retailer_slug:, country_code:, currency:)
      @retailer_slug = retailer_slug
      @country_code = country_code
      @currency = currency
    end

    def search(ingredient_name, limit: 3)
      query = normalize(ingredient_name)
      load_catalog
        .map { |row| [score(query, row), row] }
        .select { |row_score, _row| row_score.positive? }
        .sort_by { |row_score, row| [-row_score, row["price"].to_f] }
        .first(limit)
        .map.with_index(1) { |(_row_score, row), index| build_product(row, index) }
    end

    private

    def load_catalog
      @load_catalog ||= begin
        return [] unless File.exist?(catalog_path)

        YAML.load_file(catalog_path)
      end
    end

    def catalog_path
      Rails.root.join("config", "grocery_catalogs", "#{@retailer_slug.tr('-', '_')}.yml")
    end

    def build_product(row, index)
      SupermarketCatalogProvider::Product.new(
        external_id: row["external_id"] || "#{@retailer_slug}-#{index}",
        name: row["name"],
        brand: row["brand"],
        package_size: row["package_size"],
        price: row["price"],
        currency: row["currency"] || @currency,
        availability: row.fetch("availability", true),
        url: row["url"],
        retailer_slug: @retailer_slug,
        country_code: row["country_code"] || @country_code
      )
    end

    def score(query, row)
      target = normalize([row["name"], row["brand"]].compact.join(" "))
      query_tokens = query.split
      target_tokens = target.split
      (query_tokens & target_tokens).size
    end

    def normalize(value)
      ActiveSupport::Inflector.transliterate(value.to_s)
        .downcase
        .gsub(/[^a-z0-9\s]/, " ")
        .squeeze(" ")
        .strip
    end
  end
end
