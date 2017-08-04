require 'telegram/bot'
require 'spree-api-client'
require_relative 'wit_client'

telegram_token   = 'TELEGRAM_TOKEN'
wit_access_token = 'WIT_ACCESS_TOKEN'

store_url        = 'http://solidus.com/api'
store_api_url    = "#{store_url}/api"
api_key          = 'SOLIDUS_API_KEY'

class Misunderstanding < StandardError; end

WitClient.new(wit_access_token,
              Spree::API::Client.new(store_api_url, api_key)).tap do |wit|
  Telegram::Bot::Client.run(telegram_token) do |bot|
    bot.listen do |message|
      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "Hi, #{message.from.first_name}")
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      else
        response = wit.request(message.text)
        bot.api.send_message(chat_id: message.chat.id, text: response)
      end
    end
  end
end
