require 'cdo/config'

module Cdo
  # Extend Cdo::Config to process lazy-loaded secrets contained in special keys.
  module SecretsConfig
    def freeze
      lazy_load_secrets!
      super
    end

    def render(*sources)
      super.tap do |configs|
        configs.each(&method(:process_secrets!))
      end
    end

    private

    # Stores a reference to a secret so it can be resolved later.
    # Contains an optional +default_value+ specifying the default value.
    Secret = Struct.new(:tag, :default_value, :key)

    %w(Secret EnvSecret).each do |tag|
      YAML.add_domain_type('', tag, &Secret.method(:new))
    end

    # Processes `Secret` references in the provided config hash.
    # To disable all secrets processing, set `shared_secrets: false` in the config.
    # When secrets are disabled the default value will be returned without any API calls.
    def process_secrets!(config)
      return if config.nil?
      config.select {|_, v| v.is_a?(Secret)}.each do |key, secret|
        if secret.tag == 'tag::Secret' && self.shared_secrets === false
          config[key] = secret.default_value
        else
          secret.key = secret_path(env, key)
        end
      end
    end

    def secret_path(prefix, key)
      "#{prefix}/cdo/#{key}"
    end

    # Resolve secret references to lazy-loaded values.
    def lazy_load_secrets!
      self.cdo_secrets = nil
      table.select {|_k, v| v.is_a?(Secret)}.each do |key, secret|
        require 'cdo/secrets'
        cdo_secrets = self.cdo_secrets ||= Cdo::Secrets.new(logger: log)
        table[key] = cdo_secrets.lazy(secret.key, fallback: secret.default_value)
        define_singleton_method(key) do
          # Replace lazy references to the underlying object on first access,
          # in order to support 'falsey' (false / nil) values.
          val = @table[key]
          val = @table[key] = val.__getobj__ if val.respond_to?(:__getobj__)
          val
        end
      end
    end
  end
end
