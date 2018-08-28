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
      self.errors << Error.new(method, message: message)
    end

    def uniq!
      self.errors = self.uniq
    end

    def uniq
      errors.sort_by {|a, b| a.method <=> b.method }
             .reject
             .with_index(1) do |error, i|
               next_error = @errors[i]
               !next_error.nil? &&
                 error.method != next_error.method
             end
    end

    private

    attr_writer :errors
  end

  class Error
    attr_reader :method, :message

    def initialize(method, message:)
      @method = method
      @message = message
    end
  end
end
