# frozen_string_literal: true

module Repository
  class Base
    include Repository::Callbacks
    include Repository::Validations
    include Repository::Relation
    include Repository::Connection
    include Repository::Persistence
    include Repository::Query

    def initialize(params = Hash.new)
      raise ArgumentError, "initialize with a hash" unless params.kind_of? Hash

      params.each do |k, v|
        instance_variable_set("@#{k}", v)
        self.class.__send__(:attr_accessor, k.to_sym)
      end
    end

    def attributes
      self.instance_variables.inject({}) do |hash, variable|
        hash[variable.to_s.gsub(/@/,'').to_sym] = instance_variable_get(variable)
        hash
      end
    end

    def ==(other)
      return false unless self.class == other.class

      self.instance_variables.each do |variable|
        accessor_method = variable.to_s.gsub(/@/,'').to_sym
        return false unless self.send(accessor_method) == other.instance_variable_get(variable)
      end

      other.instance_variables.each do |variable|
        accessor_method = variable.to_s.gsub(/@/,'').to_sym
        return false unless other.send(accessor_method) == self.instance_variable_get(variable)
      end

      true
    end
  end
end
