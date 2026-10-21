require "rails_helper"

RSpec.describe ProfileDraftJob do
  let(:profile) { Profile.current.tap { it.update!(cv_text: "CV", cv_draft_status: "pending") } }
  let(:draft) { instance_double(Ai::ProfileDraft) }

  it "stores the draft" do
    allow(draft).to receive(:call).and_return([ { "name" => "Ana" }, nil ])

    described_class.perform_now(profile, draft:)

    expect(profile.reload).to have_attributes(cv_draft: { "name" => "Ana" }, cv_draft_status: "done")
  end

  it "records what went wrong" do
    allow(draft).to receive(:call).and_return([ {}, nil ])
    described_class.perform_now(profile, draft:)
    expect(profile.reload).to have_attributes(cv_draft_status: "failed", cv_draft_error: /não devolveu/)

    profile.update!(cv_draft_status: "pending")
    allow(draft).to receive(:call).and_raise(Ai::Client::Error.new("sem saldo", status: 402))
    described_class.perform_now(profile, draft:)
    expect(profile.reload.cv_draft_error).to include("Sem créditos")

    profile.update!(cv_draft_status: "pending")
    allow(draft).to receive(:call).and_raise(SocketError)
    described_class.perform_now(profile, draft:)
    expect(profile.reload.cv_draft_error).to include("Sem conexão")
  end

  it "does nothing unless a draft was asked for" do
    profile.update!(cv_draft_status: nil)

    expect { described_class.perform_now(profile, draft:) }.not_to(change { profile.reload.updated_at })
  end
end
