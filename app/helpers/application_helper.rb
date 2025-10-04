module ApplicationHelper
  def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: "rouge").to_html
  end

  def render_meal_distribution(data)
    return "" unless data.is_a?(Hash)

    data.map do |fecha, comidas|
      "### #{fecha}\n" +
      comidas.map do |tipo, info|
        "- **#{tipo.capitalize}:** #{info['detalle']} (#{info['calorias']} kcal)"
      end.join("\n")
    end.join("\n\n")
  end
end
