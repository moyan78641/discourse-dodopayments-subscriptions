import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class AdminDodoOrder extends EmberObject {
  static findAll(params = {}) {
    return ajax("/subscribe/admin/orders", {
      method: "get",
      data: params,
    }).then((payload) => ({
      ...payload,
      orders: payload.orders.map((order) => AdminDodoOrder.create(order)),
      subscriptions: payload.subscriptions.map((subscription) =>
        AdminDodoOrder.create({ ...subscription, record_type: "subscription" }),
      ),
    }));
  }

  static createManual(data) {
    return ajax("/subscribe/admin/orders", { method: "post", data });
  }

  updateOperation(data) {
    return ajax(`/subscribe/admin/orders/${this.id}`, {
      method: "patch",
      data,
    }).then((result) => this.setProperties(result));
  }

  get amountLabel() {
    if (this.amount_cents === null || this.amount_cents === undefined) {
      return i18n("no_value");
    }

    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currency || "USD",
    }).format(this.amount_cents / 100);
  }

  get startsAtLabel() {
    return this.formatDate(this.starts_at);
  }

  get expiresAtLabel() {
    return this.formatDate(this.expires_at);
  }

  get createdAtLabel() {
    return this.formatDate(this.created_at);
  }

  get currentPeriodEndLabel() {
    return this.formatDate(this.current_period_end);
  }

  get statusLabel() {
    return i18n(
      `discourse_dodo_subscriptions.admin.orders.statuses.${this.status}`,
    );
  }

  get sourceLabel() {
    return i18n(
      `discourse_dodo_subscriptions.admin.orders.sources.${this.source}`,
    );
  }

  formatDate(value) {
    if (!value) {
      return i18n("no_value");
    }

    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(value));
  }
}
