class Current < ActiveSupport::CurrentAttributes
  attribute :session, :profile
  delegate :user, to: :session, allow_nil: true
end
