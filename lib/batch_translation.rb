module ActionView
  module Helpers
    class FormBuilder
      def globalize_fields_for(locale, *args, &proc)
        raise ArgumentError, "Missing block" unless block_given?
        @index = @index ? @index + 1 : 1
        object_name = "#{@object_name}[globalize_translations_attributes][#{@index}]"
        # Be sure to use @object.translation and not anymore .globalize_translations like in previous versions of this code since it's the way it works nowadays in Rails (writing at the time of 2.3.5).
        object = @object.translations.find_by_locale locale.to_s
        @template.concat @template.hidden_field_tag("#{object_name}[id]", object ? object.id : ""), proc.binding
        @template.concat @template.hidden_field_tag("#{object_name}[locale]", locale), proc.binding
        @template.fields_for(object_name, object, *args, &proc)
      end
    end
  end
end

module Globalize
  module Model
    module ActiveRecord
      module Translated
        module Callbacks
          def enable_nested_attributes
            accepts_nested_attributes_for :globalize_translations
          end
        end
        module InstanceMethods
          def after_save
            init_translations
          end
          # Builds an empty translation for each available 
          # locale not in use after creation
          def init_translations
            I18n.available_locales.reject{|key| key == :root }.each do |locale|
              translation = self.globalize_translations.find_by_locale locale.to_s
              if translation.nil?
                # logger.debug "Building empty translation with locale '#{locale}'"
                globalize_translations.build :locale => locale
                save
              end
            end
          end
        end
      end
    end
  end
end