import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";

export default class DodoProduct extends EmberObject {
  static findAll() {
    return ajax("/subscribe.json", { method: "get" }).then((products) =>
      products.map((product) => DodoProduct.create(product))
    );
  }

  static find(id) {
    return ajax(`/subscribe/${id}.json`, { method: "get" }).then((product) =>
      DodoProduct.create(product)
    );
  }

  checkout() {
    return ajax("/subscribe/checkout.json", {
      method: "post",
      data: { product_id: this.id },
    });
  }

  formatAmount(amountCents) {
    if (!this.currency || amountCents === null || amountCents === undefined) {
      return null;
    }

    const amount = amountCents / 100;
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currency,
    }).format(amount);
  }

  get amountLabel() {
    if (!this.currency || this.amount_cents === null || this.amount_cents === undefined) {
      return null;
    }

    return this.formatAmount(this.amount_cents);
  }
}
