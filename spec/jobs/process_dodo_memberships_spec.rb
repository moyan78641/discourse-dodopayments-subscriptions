# frozen_string_literal: true

RSpec.describe Jobs::ProcessDodoMemberships do
  before do
    SiteSetting.discourse_dodo_subscriptions_enabled = true
    SiteSetting.discourse_dodo_subscriptions_reminder_days = "7,3,1"
    SiteSetting.discourse_dodo_subscriptions_notify_on_expiration = false
  end

  let(:user) { Fabricate(:user) }
  let(:group) { Fabricate(:group, name: "members") }
  let(:product) do
    Fabricate(:dodo_product, group_name: group.name, billing_type: "one_time")
  end

  it "expires orders and removes access" do
    order =
      Fabricate(
        :dodo_order,
        user: user,
        product: product,
        starts_at: 2.months.ago,
        expires_at: 1.minute.ago,
      )
    group.add(user)

    described_class.new.execute({})

    expect(order.reload.status).to eq("expired")
    expect(group.users).not_to include(user)
  end

  it "sends each configured reminder once" do
    order =
      Fabricate(
        :dodo_order,
        user: user,
        product: product,
        expires_at: 3.days.from_now,
      )
    DiscourseDodoSubscriptions::MembershipNotifier
      .expects(:expiry_reminder!)
      .with(order, days: 3)
      .once

    described_class.new.execute({})
  end
end
