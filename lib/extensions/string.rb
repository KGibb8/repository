# frozen_string_literal: true

module Extensions
  module String
    def constantize
      Object.const_get(self.classify)
    end

    def classify
      self.split("_").map(&:capitalize).join
    end

    def underscore
      self.scan(/[A-Z][a-z]+/).join('_').downcase
    end

    def singularize
      self.end_with?("s") ? self[0..-2] : self
    end

    def pluralize
      self.end_with?("s") ? self : self.concat("s")
    end
  end
end
