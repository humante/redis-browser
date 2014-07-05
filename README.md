# Redis Browser

## Features

* List all keys as tree
* See content of all redis types
* List pagination
* Pretty print json values
* Search keys
* Can be mounted to Rails applications as engine

## Installation

```bash
$ gem install redis-browser
```

## Usage

### Standalone

```bash
$ redis-browser
```

### As engine

Add to gemfile

```ruby
gem 'redis-browser'
```

And to routes.rb

```ruby
mount RedisBrowser::Web => '/redis-browser'
```

## Screenshots

![Browse keys](https://dl.dropboxusercontent.com/u/70986/redis-browser/2.png)
![See list with pagination](https://dl.dropboxusercontent.com/u/70986/redis-browser/3.png)
![ZSET support](https://dl.dropboxusercontent.com/u/70986/redis-browser/4.png)
![JSON pretty print](https://dl.dropboxusercontent.com/u/70986/redis-browser/5.png)
![Configuration](https://dl.dropboxusercontent.com/u/70986/redis-browser/6.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
