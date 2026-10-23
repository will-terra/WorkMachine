# Interview preparation: the AI sheet belongs to an application (the posting is optional, since an
# application may be typed by hand), the interview date comes from the e-mail or the form, and a
# reminder goes out the day before.
class AddInterviewPrep < ActiveRecord::Migration[8.1]
  def change
    change_column_null :ai_artifacts, :job_posting_id, true
    add_reference :ai_artifacts, :job_application, index: true # removed with the application (dependent: :destroy)

    add_column :job_applications, :interview_at, :datetime
    add_column :job_applications, :interview_reminded_at, :datetime

    add_column :settings, :notify_interviews, :boolean, default: true, null: false
  end
end
