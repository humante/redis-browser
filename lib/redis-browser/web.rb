module RedisBrowser
  module WebHelpers
    def root_path
      "#{env['SCRIPT_NAME']}/"
    end

    def js_env
      jsEnv = {
        root_path: root_path,
        connections: settings.connections,
        connection: params[:connection] || settings.connections.keys.first
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
      conn = settings.connections[params[:connection]]
      conn = {url: conn} unless conn.is_a?(Hash)
      @browser ||= Browser.new(conn)
    end
  end
end
