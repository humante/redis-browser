module RedisBrowser
  module WebHelpers
    def root_path
      "#{env['SCRIPT_NAME']}/"
    end

    def js_env
      jsEnv = {
        root_path: "#{root_path}"
      }

      "jsEnv = #{MultiJson.dump(jsEnv)};"
    end
  end

  class CoffeeHandler < Sinatra::Base
    set :views, File.dirname(__FILE__) + '/templates/coffee'

    get "/js/app.js" do
      coffee :app
    end
  end

  class Web < Sinatra::Base
    helpers Sinatra::JSON, WebHelpers
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
      connection = if ENV['REDIS_URL']
        ENV['REDIS_URL'].sub(/\Aredis:\/\//, '')
      else
        params[:connection]
      end
      @browser ||= Browser.new(connection, params[:database])
    end
  end
end
