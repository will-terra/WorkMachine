class ApplicationJob < ActiveJob::Base
  # "Today" and the times of the jobs follow the time zone of the profile.
  around_perform { |_job, block| Time.use_zone(Profile.current.time_zone, &block) }

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
