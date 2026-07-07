import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

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

  get createdAtLabel() {
    return this.formatDate(this.created_at);
  }

  get cancelAtPeriodEndLabel() {
    return i18n(this.cancel_at_period_end ? "yes_value" : "no_value");
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
