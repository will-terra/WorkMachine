# Suggestions to the profile learned from the triage, without AI: plain counts over the jobs you
# saved and dismissed by hand and over the applications that got an answer.
#
#   avoid    a technology outside the profile that keeps showing up in the jobs you dismiss
#   promote  a skill whose jobs you save, or that answer you, much more than the others
#   demote   a skill whose jobs you almost never save
#
# Each rule compares with your own average, so a strict triage (few saves) still gives fair advice.
class ProfileSuggestions
  MIN_DECISIONS = 20 # nothing to say before a few triages
  SAMPLE = 600 # the most recent decisions of each kind
  LIMIT = 4

  Suggestion = Data.define(:kind, :term, :level, :count, :saved, :share, :average, :ratio) do
    def key = [ kind, Profile.normalize_text(term).squish, level ].compact.join(":")
  end

  def self.current(profile = Profile.current, setting = Setting.current)
    stamp = [ JobPosting.maximum(:updated_at), JobApplication.maximum(:updated_at), profile.updated_at ].map(&:to_i)
    suggestions = Rails.cache.fetch([ "profile-suggestions", *stamp ], expires_in: 12.hours) { new(profile).call }
    suggestions.reject { setting.dismissed_suggestions.include?(it.key) }
  end

  def initialize(profile = Profile.current)
    @profile = profile
  end

  def call
    return [] if saved_texts.size + dismissed_texts.size < MIN_DECISIONS || saved_texts.empty?

    (promotions + avoids + demotions).first(LIMIT)
  end

  # The profile with the suggestion applied (Perfil → Sugestões → aplicar).
  def apply(suggestion)
    case suggestion.kind
    when "avoid" then @profile.update!(avoid_terms: @profile.avoid_terms + [ suggestion.term ])
    else @profile.update!(skills: @profile.skills.map { it["name"] == suggestion.term ? it.merge("level" => suggestion.level) : it })
    end
  end

  private
    def avoids
      vocabulary.filter_map do |term|
        regex = Profile.terms_regex([ term ])
        dismissed, saved = count(dismissed_texts, regex), count(saved_texts, regex)
        total = dismissed + saved
        expected = total * average
        next unless total >= 8 && expected >= 2 && saved <= expected * 0.25

        Suggestion.new(kind: "avoid", term:, level: nil, count: dismissed, saved:, share: nil, average: nil, ratio: nil)
      end.sort_by { -it.count }
    end

    def promotions
      @profile.skills.reject { it["level"] == "essential" }.filter_map do |skill|
        regex = skill_regex(skill)
        level = next_level(skill["level"], 1)
        if (ratio = answer_ratio(regex))
          Suggestion.new(kind: "promote", term: skill["name"], level:, count: nil, saved: nil, share: nil, average: nil, ratio:)
        else
          saved = count(saved_texts, regex)
          total = saved + count(dismissed_texts, regex)
          share = total.positive? ? saved.fdiv(total) : 0
          next unless saved >= 4 && share >= average * 2 && share >= average + 0.15

          Suggestion.new(kind: "promote", term: skill["name"], level:, count: total, saved:, share: percent(share), average: percent(average), ratio: nil)
        end
      end
    end

    def demotions
      @profile.skills.reject { it["level"] == "extra" }.filter_map do |skill|
        regex = skill_regex(skill)
        saved = count(saved_texts, regex)
        total = saved + count(dismissed_texts, regex)
        expected = total * average
        next unless total >= 20 && expected >= 3 && saved <= expected * 0.25

        Suggestion.new(kind: "demote", term: skill["name"], level: next_level(skill["level"], -1), count: total, saved:, share: nil, average: nil, ratio: nil)
      end
    end

    # How many times more the applications to jobs with the skill got an answer.
    def answer_ratio(regex)
      with = applications.select { regex.match?(it.last) }
      return if with.size < 4 || answer_rate(applications).zero?

      ratio = answer_rate(with) / answer_rate(applications)
      ratio.round(1) if ratio >= 2 && with.count(&:first) >= 2
    end

    def answer_rate(list)
      list.empty? ? 0.0 : list.count(&:first).fdiv(list.size)
    end

    # [answered?, text] of the applications sent to a posting.
    def applications
      @applications ||= JobApplication.where.not(status: "saved").where.not(job_posting_id: nil).includes(:job_posting)
                                      .order(updated_at: :desc).limit(SAMPLE).map { [ it.responded_on.present?, text(it.job_posting) ] }
    end

    def saved_texts
      @saved_texts ||= JobPosting.where(triage: "saved").or(JobPosting.where(id: JobApplication.select(:job_posting_id)))
                                 .order(updated_at: :desc).limit(SAMPLE).map { text(it) }
    end

    def dismissed_texts
      @dismissed_texts ||= JobPosting.where(triage: "dismissed", auto_dismissed_reason: nil).where.not(id: JobApplication.where.not(job_posting_id: nil).select(:job_posting_id))
                                     .order(updated_at: :desc).limit(SAMPLE).map { text(it) }
    end

    # Your share of saves among the jobs you decided on.
    def average
      @average ||= saved_texts.size.fdiv(saved_texts.size + dismissed_texts.size)
    end

    # Technologies of every area, minus what the profile already has.
    def vocabulary
      known = (@profile.skills.flat_map { [ it["name"], *it["synonyms"] ] } + @profile.avoid_terms).map { Profile.normalize_text(it).squish }
      Area.all.flat_map { it.skills.values.flatten }.uniq { Profile.normalize_text(it).squish }.reject { known.include?(Profile.normalize_text(it).squish) }
    end

    def skill_regex(skill)
      Profile.terms_regex([ skill["name"], *skill["synonyms"] ])
    end

    def next_level(level, step)
      levels = Profile::LEVELS.keys.reverse # extra, important, essential
      levels[(levels.index(level) + step).clamp(0, levels.size - 1)]
    end

    def count(texts, regex)
      texts.count { regex.match?(it) }
    end

    def text(posting)
      Profile.normalize_text(posting.title, posting.description)
    end

    def percent(share)
      (share * 100).round
    end
end
