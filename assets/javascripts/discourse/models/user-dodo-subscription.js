import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

const ACTIVE_STATUSES = ["active", "renewed"];
const ENDING_STATUSES = ["cancelled", "failed", "expired", "on_hold"];

export default class UserDodoSubscription extends EmberObject {
  static findAll() {
    return ajax("/subscribe/user/subscriptions.json", { method: "get" }).then(
      (subscriptions) =>
        subscriptions.map((subscription) =>
          UserDodoSubscription.create(subscription)
        )
    );
  }

  get productName() {
    return this.product?.name || i18n("no_value");
  }

  get rateLabel() {
    const amountLabel = this.amountLabel;
    const intervalLabel = this.intervalLabel;

    if (amountLabel && intervalLabel) {
      return `${amountLabel} / ${intervalLabel}`;
    }

    return amountLabel || intervalLabel || i18n("no_value");
  }

  get amountLabel() {
    const amountCents = this.product?.amount_cents;
    const currency = this.product?.currency;

    if (!currency || amountCents === null || amountCents === undefined) {
      return null;
    }

    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency,
    }).format(amountCents / 100);
  }

  get intervalLabel() {
    const interval = this.product?.recurring_interval;
    if (!interval) {
      return null;
    }

    return i18n(`discourse_dodo_subscriptions.intervals.${interval}`);
  }

  get currentPeriodEndLabel() {
    return this.formatDate(this.current_period_end);
  }

  get periodEndTitle() {
    return i18n(
      this.cancel_at_period_end
        ? "discourse_dodo_subscriptions.user.subscriptions.expires_at"
        : "discourse_dodo_subscriptions.user.subscriptions.renews_at"
    );
  }

  get createdAtLabel() {
    return this.formatDate(this.created_at);
  }

  get normalizedStatus() {
    return (this.status || "unknown").toString();
  }

  get statusLabel() {
    const status = this.normalizedStatus;
    const knownStatuses = [
      "active",
      "renewed",
      "cancelled",
      "failed",
      "expired",
      "on_hold",
      "unknown",
    ];

    if (knownStatuses.includes(status)) {
      return i18n(
        `discourse_dodo_subscriptions.user.subscriptions.statuses.${status}`
      );
    }

    return status;
  }

  get statusClassName() {
    const status = this.normalizedStatus;
    let statusGroup = "neutral";

    if (ACTIVE_STATUSES.includes(status)) {
      statusGroup = "active";
    } else if (ENDING_STATUSES.includes(status)) {
      statusGroup = "ended";
    }

    return `dodo-user-subscription__status dodo-user-subscription__status--${statusGroup}`;
  }

  get renewalLabel() {
    if (this.cancel_at_period_end) {
      return i18n(
        "discourse_dodo_subscriptions.user.subscriptions.expires_at_period_end"
      );
    }

    if (ACTIVE_STATUSES.includes(this.normalizedStatus)) {
      return i18n(
        "discourse_dodo_subscriptions.user.subscriptions.renews_automatically"
      );
    }

    return i18n("discourse_dodo_subscriptions.user.subscriptions.not_renewing");
  }

  get hasDuplicateSubscriptions() {
    return Number(this.duplicate_subscription_count) > 0;
  }

  get duplicateSubscriptionNotice() {
    if (!this.hasDuplicateSubscriptions) {
      return null;
    }

    return i18n(
      "discourse_dodo_subscriptions.user.subscriptions.duplicate_notice",
      { count: this.duplicate_subscription_count }
    );
  }

  formatDate(value) {
    if (!value) {
      return i18n("no_value");
    }

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return i18n("no_value");
    }

    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
    }).format(date);
  }
}
