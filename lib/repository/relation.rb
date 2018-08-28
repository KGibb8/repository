# frozen_string_literal: true

module Repository
  module Relation
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_many(association, options = {})
        association_class_name = association.to_s.singularize.classify
        primary_association_name = self.name.underscore

        self.__send__(:define_method, association) do
          association_class = Object.const_get(association_class_name)
          Record::Collection.new(association_class.where(primary_association_name.to_sym => self))
        end
      end

      def belongs_to(association, options = {})
        association_class_name = association.to_s.classify
        foreign_association_name = self.name.underscore

        self.__send__(:define_method, association) do
          association_class = Object.const_get(association_class_name)
          association_class.find_by(foreign_association_name => self)
        end
      end
    end
  end
end
