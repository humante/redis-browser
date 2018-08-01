module RedisBrowser
  class Browser
    def initialize(conn = {})
      @conn = conn
    end

    def split_key(key)
      if key =~ /^(.+?)(:+|\/+|\.+).+$/
        [$1, $2]
      else
        [key, nil]
      end
    rescue ArgumentError
      [key, nil]
    end

    def keys(namespace = nil)
      begin
        if namespace.to_s.strip.empty?
          pattern = "*"
          namespace = ""
        else
          pattern = namespace + "*"
        end
      rescue ArgumentError
        pattern, namespace = "*", ""
      end

      redis.keys(pattern).inject({}) do |acc, key|
        key.slice!(namespace) if namespace

        ns, sep = split_key(key)

        begin
          unless ns.strip.empty?
            acc[ns] ||= {
              :name => ns,
              :full => namespace + ns + sep.to_s,
              :count => 0,
              :has_children => false
            }
            acc[ns][:count] += 1

            # If this key contains separators, then it must have children
            if sep
              acc[ns][:has_children] = true
            end
          end
        rescue ArgumentError
        end

        acc
      end.values.sort_by {|e| e[:name] }
    end

    def item_type(e)
      begin
        ["json", MultiJson.decode(e)]
      rescue MultiJson::LoadError
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
      key ||= ""
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
      ttl  = redis.ttl(key)
      data = case type
      when "string"
        type, value = item_type(redis.get(key))
        {:value => fix_encoding(value), :type => type}
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
        :type => type,
        :ttl  => ttl
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
        r = Redis.new(@conn)
        auth = @conn['auth']
        r.auth(auth) if auth
        r
      end
    end

    private
    def fix_encoding(object)
      return object unless object.is_a?(String)

      encodings = %w(UTF-8 ISO-8859-1)
      valid_encodings = encodings.map do |encoding|
        object.clone.force_encoding(encoding)
      end.compact.select(&:valid_encoding?)

      valid_encodings.first || object
    end
  end
end
