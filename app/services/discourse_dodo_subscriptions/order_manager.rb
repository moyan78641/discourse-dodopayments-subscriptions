# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class OrderManager
    def self.open!(**args)
      new.open!(**args)
    end

    def self.set_expiry!(**args)
      new.set_expiry!(**args)
    end

    def self.revoke!(**args)
      new.revoke!(**args)
    end

    def open!(
      user:,
      product:,
      external_id:,
      source:,
      amount_cents: nil,
      currency: nil,
      payment_method: nil,
      actor: nil,
      note: nil,
      metadata: {},
      duration_days: nil,
      notify_user: true
    )
      order =
        find_or_create_order!(
          user: user,
          product: product,
          external_id: external_id,
          source: source,
          amount_cents: amount_cents,
          currency: currency,
          payment_method: payment_method,
          actor: actor,
          note: note,
          metadata: metadata,
          duration_days: duration_days,
        )

      AccessManager.sync!(user: order.user, group_name: order.product.group_name)
      if notify_user && order.status == "succeeded"
        MembershipNotifier.purchase_opened!(order)
      end
      order
    end

    def set_expiry!(order:, expires_at:, actor:, note: nil, notify_user: false)
      previous_expiry = order.expires_at
      order.update!(
        expires_at: expires_at,
        status: expires_at > Time.zone.now ? "succeeded" : "expired",
        note: note,
      )
      record_event(
        order,
        actor,
        "expiry_changed",
        previous_expires_at: previous_expiry,
        expires_at: expires_at,
        note: note,
      )
      AccessManager.sync!(user: order.user, group_name: order.product.group_name)
      if notify_user && order.status == "succeeded"
        MembershipNotifier.purchase_opened!(order, force: true)
      end
      order
    end

    def revoke!(order:, actor:, note: nil, notify_user: false)
      order.update!(status: "revoked", note: note)
      record_event(order, actor, "revoked", note: note)
      AccessManager.sync!(user: order.user, group_name: order.product.group_name)
      if notify_user && !AccessManager.active?(user: order.user, group_name: order.product.group_name)
        MembershipNotifier.expired!(order)
      end
      order
    end

    private

    def find_or_create_order!(**attributes)
      Order.find_by(external_id: attributes[:external_id]) ||
        Order.transaction do
          Order.find_by(external_id: attributes[:external_id]) || create_order!(**attributes)
        end
    rescue ActiveRecord::RecordNotUnique
      Order.find_by!(external_id: attributes[:external_id])
    end

    def create_order!(
      user:,
      product:,
      external_id:,
      source:,
      amount_cents:,
      currency:,
      payment_method:,
      actor:,
      note:,
      metadata:,
      duration_days:
    )
      starts_at = next_membership_start(user, product)
      expires_at =
        if duration_days.present?
          starts_at + duration_days.to_i.days
        else
          product.advance_membership_from(starts_at)
        end
      order =
        Order.create!(
          user: user,
          product: product,
          external_id: external_id,
          source: source,
          status: "succeeded",
          amount_cents: amount_cents,
          currency: currency.presence || product.currency,
          payment_method: payment_method,
          starts_at: starts_at,
          expires_at: expires_at,
          created_by: actor,
          note: note,
          metadata: metadata.presence || {},
        )
      record_event(order, actor, "created", source: source, note: note)
      order
    end

    def next_membership_start(user, product)
      latest_expiry =
        Order
          .joins(:product)
          .where(
            user_id: user.id,
            status: Order::ACTIVE_STATUSES,
          )
          .where(Product.table_name => { group_name: product.group_name })
          .maximum(:expires_at)

      [Time.zone.now, latest_expiry].compact.max
    end

    def record_event(order, actor, action, details = {})
      order.events.create!(
        actor: actor,
        action: action,
        details: details,
        created_at: Time.zone.now,
      )
    end
  end
end
