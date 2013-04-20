require File.expand_path("../version", __FILE__)
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
  def keys_tree(sep = /:+|\//)
    keys = {}
    full = {}

    redis.keys.each do |key|
      chunks = key.split(sep, 7)
      full[chunks] = key
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
          :full => full[np],
          :children => f.call(np, v)
        }
      end.sort_by {|k| k[:name] }
    end

    f.call([], keys)
  end

  def item_type(e)
    begin
      ["json", MultiJson.decode(e)]
    rescue MultiJson::LoadError => ex
      ["string", e]
    end
  end

  def get_list(key, opts = {})
    start = opts[:start] ? opts[:start].to_i : 0
    stop  = opts[:stop] ? opts[:stop].to_i : 99

    length = redis.llen(key)
    values = redis.lrange(key, start, stop).map.with_index do |e, i|
      type, value = item_type(e)
      {:type => type, :value => value, :index => start + i}
    end

    {:length => length, :values => values}
  end

  def get_set(key)
    values = redis.smembers(key).map do |e|
      type, value = item_type(e)
      {:type => type, :value => value}
    end

    {:values => values }
  end

  def get_zset(key)
    values = redis.zrange(key, 0, -1, :withscores => true).map do |e, score|
      type, value = item_type(e)
      {:type => type, :value => value, :score => score}
    end

    {:values => values }
  end

  def get_hash(key)
    value = Hash[redis.hgetall(key).map do |k,v|
      type, value = item_type(v)
      [k, {:type => type, :value => value}]
    end]

    {:value => value}
  end

  def get(key, opts = {})
    type = redis.type(key)
    data = case type
    when "string"
      {:value => redis.get(key)}
    when "list"
      get_list(key, opts)
    when "set"
      get_set(key)
    when "zset"
      get_zset(key)
    when "hash"
      get_hash(key)
    else
      {:value => "Not found"}
    end

    {
      :full => key,
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
