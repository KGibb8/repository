# frozen_string_literal: true

module Repository
  class Errors
    include Enumerable

    attr_reader :errors, :record

    def initialize(record, error = nil)
      @errors = [error].compact
      @record = record
    end

    def each
      if block_given?
        self.errors.each { |error| yield(error) }
      else
        self.errors.each
      end
    end

    def add(method, message)
      self.errors << Error.new(method, message)
    end

    def blank?
      self.errors.nil? || self.errors.empty?
    end

    def uniq!
      self.errors = self.uniq
    end

    def uniq
      self.errors.sort {|a, b| a.method.to_s <=> b.method.to_s }
                 .reject
                 .with_index(1) { |error, i| !@errors[i].nil? && error.method != @errors[i].method }
    end

    private

    attr_writer :errors
  end

  class Error
    attr_reader :method, :message

    def initialize(method, message)
      @method = method
      @message = message
    end
  end
end
