class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Portuguese label of an enum value, from config/locales/pt-BR.yml (enums.<model>.<attribute>.<value>).
  def self.human_enum(attribute, value)
    return "" if value.blank?

    I18n.t("enums.#{model_name.i18n_key}.#{attribute}.#{value}", default: value.to_s.humanize)
  end

  def self.enum_options(attribute)
    public_send(attribute.to_s.pluralize).keys.map { |value| [ human_enum(attribute, value), value ] }
  end

  def human_enum(attribute)
    self.class.human_enum(attribute, public_send(attribute))
  end
end
