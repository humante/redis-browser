require 'sinatra/base'
require 'multi_json'
require 'sinatra/json'
require 'slim'
require 'coffee-script'
require 'redis'


class CoffeeHandler < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/templates/coffee'

  get "/js/app.js" do
    coffee :app
  end
end

class Browser
  def keys_tree(sep = ":")
    keys = {}

    redis.keys.each do |key|
      chunks = key.split(sep)
      chunks.inject(keys) do |xs, x|
        xs[x] ||= {}
        xs[x]
      end
    end

    f = lambda do |prefix, hash|
      hash.map do |k,v|
        np = (prefix + [k])
        {
          :name => k,
          :full => np.join(sep),
          :children => f.call(np, v)
        }
      end
    end

    f.call([], keys)
  end

  def get_list(key, opts = {})
    start = opts[:start] ? opts[:start].to_i : 0
    stop  = opts[:stop] ? opts[:stop].to_i : 99

    length = redis.llen(key)
    values = redis.lrange(key, start, stop).map.with_index do |e, i|
      type, value = begin
        ["json", MultiJson.decode(e)]
      rescue MultiJson::LoadError => ex
        ["string", e]
      end

      {:type => type, :value => value, :index => start + i}
    end

    {:length => length, :values => values}
  end

  def get(key, opts = {})
    type = redis.type(key)
    data = case type
    when "string"
      {:value => redis.get(key)}
    when "list"
      get_list(key, opts)
    else
      {:value => "Not found"}
    end

    {
      :name => key,
      :type => type
    }.merge(data)
  end

  def redis
    @redis ||= Redis.new
  end
end

class App < Sinatra::Base
  helpers Sinatra::JSON
  use CoffeeHandler

  set :public_dir, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/templates'

  get '/' do
    slim :index
  end

  get '/keys.json' do
    json browser.keys_tree
  end

  get '/key.json' do
    json browser.get(params[:key], params)
  end

  def browser
    @browser ||= Browser.new
  end
end



if __FILE__ == $0
    App.run! :port => 4567
end
