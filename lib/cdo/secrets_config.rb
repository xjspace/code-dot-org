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
    Secret = Struct.new(:key)

    YAML.add_domain_type('', 'Secret') {Secret.new}

    # Processes `Secret` references in the provided config hash.
    def process_secrets!(config)
      return if config.nil?
      config.select {|_, v| v.is_a?(Secret)}.each do |key, secret|
        secret.key ||= secret_path(env, key)
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
        table[key] = cdo_secrets.lazy(secret.key, raise_not_found: true)
        define_singleton_method(key) do
          # Replace lazy references to the underlying object on first access,
          # in order to support 'falsey' (false / nil) values.
          val = @table[key]
          val = @table[key] = val.__getobj__ if val.respond_to?(:__getobj__)
          val
        end
      end
    end

    # Returns a YAML fragment clearing all secrets by overriding their values to `nil`.
    # Any exceptions or defaults can be re-added later in the YAML document, after secrets have been cleared.
    def clear_secrets
      @secrets ||= []
      @secrets |= table.select {|_, v| v.is_a?(Secret)}.keys.map(&:to_s)
      @secrets.product([nil]).to_h.to_yaml.gsub("---\n", '')
    end
  end
end
