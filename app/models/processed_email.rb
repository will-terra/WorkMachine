# A LinkedIn alert e-mail already imported, so the hourly import never reads it twice.
class ProcessedEmail < ApplicationRecord
  validates :message_id, presence: true, uniqueness: true
end
