# "Montar perfil a partir do CV" in the background: the draft goes to profile.cv_draft and the
# Perfil screen offers to open it in the form for review.
class ProfileDraftJob < ApplicationJob
  queue_as :default

  def perform(profile, draft: Ai::ProfileDraft.new)
    return unless profile.cv_draft_status == "pending"

    attributes, result = draft.call(profile.cv_text)
    if attributes.empty?
      profile.update!(cv_draft_status: "failed", cv_draft_error: result&.refused? ? "A IA recusou o pedido." : "A IA não devolveu um rascunho. Tente de novo.")
    else
      profile.update!(cv_draft: attributes, cv_draft_status: "done", cv_draft_error: nil)
    end
  rescue Ai::Client::Error => e
    profile.update!(cv_draft_status: "failed", cv_draft_error: Ai::Client.explain(e))
  rescue SocketError, SystemCallError, Timeout::Error => e
    profile.update!(cv_draft_status: "failed", cv_draft_error: "Sem conexão com o OpenRouter (#{e.class}).")
  end
end
