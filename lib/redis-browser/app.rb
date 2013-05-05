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
  def initialize(conn = nil, db = 0)
    @conn = conn
    @db = db
  end

  def split_key(key)
    if key =~ /^(.+?)(:+|\/+|\.+).+$/
      [$1, $2]
    else
      [key, nil]
    end
  end

  def keys(namespace = nil)
    if namespace.to_s.strip.empty?
      pattern = "*"
      namespace = ""
    else
      pattern = namespace + "*"
    end

    redis.keys(pattern).inject({}) do |acc, key|
      key.slice!(namespace) if namespace

      ns, sep = split_key(key)

      unless ns.strip.empty?
        acc[ns] ||= {
          :name => ns,
          :full => namespace + ns + sep.to_s,
          :count => 0
        }
        acc[ns][:count] += 1
      end

      acc
    end.values.sort_by {|e| e[:name] }
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

  def get_keys(key)
    key << "*" unless key.end_with?("*")

    values = redis.keys(key).map do |k|
      {:name => k, :full => k}
    end

    {:values => values}
  end

  def delete(pattern)
    redis.del(redis.keys(pattern))
  end

  def get(key, opts = {})
    type = redis.type(key)
    data = case type
    when "string"
      type, value = item_type(redis.get(key))
      {:value => value, :type => type}
    when "list"
      get_list(key, opts)
    when "set"
      get_set(key)
    when "zset"
      get_zset(key)
    when "hash"
      get_hash(key)
    else
      get_keys(key)
    end

    {
      :full => key,
      :type => type
    }.merge(data)
  end

  def ping
    redis.ping == "PONG"
    {:ok => 1}
  rescue => ex
    {:error => ex.message}
  end

  def redis
    @redis ||= begin
      conn = @conn || "127.0.0.1:6379"
      db = @db || 0

      opts = if conn.start_with?("/")
        {:path => conn}
      else
        host, port = conn.split(":", 2)
        {:host => host, :port => port}
      end

      r = Redis.new(opts)
      r.select(db)
      r
    end
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

  get '/ping.json' do
    json browser.ping
  end

  get '/keys.json' do
    json browser.keys(params[:namespace])
  end

  get '/key.json' do
    json browser.get(params[:key], params)
  end

  delete '/key.json' do
    browser.delete(params[:key])
    json :ok => true
  end

  def browser
    @browser ||= Browser.new(params[:connection], params[:database])
  end
end
