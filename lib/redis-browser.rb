require 'sinatra/base'
require 'multi_json'
require 'sinatra/json'
require 'slim'
require 'coffee-script'
require 'redis'
require 'redis-browser/version'
require 'redis-browser/browser'
require 'redis-browser/web'

module RedisBrowser
  def self.configure(opts)
    Web.configure do |config|
      opts.each do |k, v|
        config.set k, v
      end
    end
  end
end
