# Sends one desktop notification (Web Push) about the postings that arrived in a run of the
# aggregator or of the LinkedIn import with a score at or above Setting#notify_min_score.
# Each posting is notified once (notified_at).
class NewPostingsNotifier
  TOP = 3

  def self.call(since:)
    new.call(since:)
  end

  # Returns the number of postings notified.
  def call(since:)
    setting = Setting.current
    return 0 unless setting.notifications_enabled?

    postings = JobPosting.triage_new.where(notified_at: nil, created_at: since..)
                         .where(score: setting.notify_min_score..).ranked.to_a
    return 0 if postings.empty?

    JobPosting.where(id: postings.map(&:id)).update_all(notified_at: Time.current)
    PushSender.deliver_all(message(postings, setting.notify_min_score))
    postings.size
  end

  private
    def message(postings, min_score)
      if postings.one?
        posting = postings.first
        { title: "Vaga nova com nota #{posting.score}", body: line(posting), path: "/vagas/#{posting.id}", tag: "new-postings" }
      else
        lines = postings.first(TOP).map { "#{it.score} · #{line(it)}" }
        lines << "e mais #{postings.size - TOP}" if postings.size > TOP
        { title: "#{postings.size} vagas novas com nota #{min_score}+", body: lines.join("\n"), path: "/vagas?min_score=#{min_score}", tag: "new-postings" }
      end
    end

    def line(posting)
      "#{posting.title} · #{posting.display_company} (#{posting.human_enum(:remote_scope)})".truncate(120)
    end
end
