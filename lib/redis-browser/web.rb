module RedisBrowser
  class CoffeeHandler < Sinatra::Base
    set :views, File.dirname(__FILE__) + '/templates/coffee'

    get "/js/app.js" do
      coffee :app
    end
  end

  class Web < Sinatra::Base
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
end
