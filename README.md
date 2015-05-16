# Redis Browser [![Gem Version](https://badge.fury.io/rb/redis-browser.png)](http://badge.fury.io/rb/redis-browser)

## Features

* List all keys as tree
* See content of all redis types
* List pagination
* Pretty print json values
* Search keys
* Can be mounted to Rails applications as engine
* Can connect to multiple databases

## Installation

```bash
$ gem install redis-browser
```

## Usage

### Standalone

```bash
$ redis-browser
```

You can predefine a list of available connections in a YAML file in couple of ways.

```yaml
connections:
  default:
    url: redis://127.0.0.1:6379/0
  production:
    host: mydomain.com
    port: 6666
    db: 1
    auth: password
```

Then start with

```bash
$ redis-browser -C path/to/config.yml
```

Run with `--help` to see what other options are available.

### As engine

Add to gemfile

```ruby
gem 'redis-browser'
```

And to routes.rb

```ruby
mount RedisBrowser::Web => '/redis-browser'
```

Use `config/initializers/redis-browser.rb` to predefine a list of available connections

```ruby
config = Rails.root.join('config', 'redis-browser.yml')
settings = YAML.load(ERB.new(IO.read(config)).result)
RedisBrowser.configure(settings)
```

### Protect with HTTP Basic Auth

`RedisBrowser::Web` is a Sinatra app, so you can inject any Rack middleware into it.

```ruby
# config/initializers/redis-browser.rb
RedisBrowser::Web.class_eval do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == 'foo' && password == 'bar'
  end
end
```

## Screenshots

![Browse keys](https://dl.dropboxusercontent.com/u/70986/redis-browser/2.png)
![See list with pagination](https://dl.dropboxusercontent.com/u/70986/redis-browser/3.png)
![ZSET support](https://dl.dropboxusercontent.com/u/70986/redis-browser/4.png)
![JSON pretty print](https://dl.dropboxusercontent.com/u/70986/redis-browser/5.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
