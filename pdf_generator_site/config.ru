# config.ru
%w{
  sinatra
  sinatra/json
  airrecord
  redis
  ./app
}.each { |r| require r }

enable :sessions
secret = Digest::MD5.hexdigest(SecureRandom.hex)
set :session_secret, secret

configure :production do
  disable :show_exceptions
  uri = URI.parse("redis://redis-19094.c10.us-east-1-4.ec2.cloud.redislabs.com:19094")
  Redis.current = Redis.new(host: uri.host, port: uri.port, password: "9dw81cl47qVkOSpHyU8h0EW6D3G5JPTY")
end

configure :development do
  enable :logging
  uri = URI.parse("redis://redis-19094.c10.us-east-1-4.ec2.cloud.redislabs.com:19094")
  Redis.current = Redis.new(host: uri.host, port: uri.port, password: "9dw81cl47qVkOSpHyU8h0EW6D3G5JPTY")
end

run Sinatra::Application
