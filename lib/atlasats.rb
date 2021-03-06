require 'rubygems'
require 'bundler/setup'
require 'eventmachine'
require 'httparty'
require 'faye'

class AtlasClient
  include HTTParty
  
  def initialize(buri, apikey)
		@baseuri = buri
    @options = { :headers => { "Authorization" => "Token token=\"#{apikey}\"" }, :base_uri => HTTParty.normalize_base_uri(@baseuri) }
  end
  
  def with_auth(body=nil, &block)
    r = block.call(body.nil? ? @options : @options.merge(:body => body))
		r.parsed_response
  end
  
  def place_market_order(side, quantity)
    with_auth :side => side, :quantity => quantity, :type => "market" do |options|
      self.class.post("/api/v1/orders", options)
    end
  end
  
  def place_limit_order(item, currency, side, quantity, price)
    with_auth :item => item, :currency => currency, :side => side, :quantity => quantity, :type => "limit", :price => price do |options|
      self.class.post("/api/v1/orders", options)
    end
  end
  
  def order_info(orderid)
    with_auth nil do |options|
      self.class.get("/api/v1/orders/#{orderid}", options)
    end
  end
  
  def cancel_order(orderid)
    with_auth nil do |options|
      self.class.delete("/api/v1/orders/#{orderid}", options)
    end
  end
  
  # account
  def account_info()
    with_auth nil do |options|
      self.class.get('/api/v1/account', options)
    end
  end
  
  # market data
  def subscribe_quotes(&block)
    Thread.new do
      EM.run {
        client = Faye::Client.new("https://#{@baseuri}:4000/api")
        client.subscribe("/quotes") do |msg|
          block.call(msg)
        end
      }
    end
  end
  
  def subscribe_trades(&block)
    Thread.new do
      EM.run {
        client = Faye::Client.new("https://#{@baseuri}:4000/api")
        client.subscribe("/trades") do |msg|
          block.call(msg)
        end
      }
    end
  end
end

class AtlasAdvancedClient < AtlasClient
  def cancel_all_orders()
    account = account_info
    orders = account["orders"]
    orders.each do |order|
      cancel_order(order)
    end
  end
end


