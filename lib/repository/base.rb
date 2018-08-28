# frozen_string_literal: true

module Repository
  class Base
    include Repository::Callbacks
    include Repository::Validations
    include Repository::Relation
    include Repository::Persistence

    def initialize(params = Hash.new)
      unless params.kind_of? Hash
        raise ArgumentError, "initialize with a hash"
      end

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

    class << self
      def all
        collection
      end

      def where(params)
        collection.where(params)
      end

      def find_by(params)
        collection.find_by(params)
      end

      private

      def collection
        Repository::Collection.new(records)
      end
    end
  end
end
