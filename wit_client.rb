require 'wit'

class WitClient
  def initialize(access_token, solidus_api_client)
    @solidus_api_client = solidus_api_client
    @wit_access_token = access_token
  end

  def solidus_client
    @solidus_api_client
  end

  def wit
    @wit = Wit.new(access_token: @wit_access_token)
  end

  def request(text)
    response = wit.message(text)
    intent = response.dig('entities', 'intent')&.first

    raise Misunderstanding, "Can't understand #{response['_text']}" if intent['confidence'] < 0.9

    case intent['value']
    when 'search_product'
      query_search = response.dig('entities', 'local_search_query')

      raise Misunderstanding, "search param missing" if query_search.nil?

      products = solidus_client.products(q: { name_cont: query_search.first['value'] })
      products.map do |product|
        [
          product.name,
          product.display_price,
          product.master.images.first.large_url
        ].join "\n"
      end.join("\n\n")
    else
      raise Misunderstanding, "Can't find intent #{intent['value']}"
    end
  rescue Misunderstanding => e
    e.message
  rescue StandardError => e
    'Sorry, Something went wrong'
  end
end
