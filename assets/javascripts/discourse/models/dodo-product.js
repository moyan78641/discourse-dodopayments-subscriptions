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
    return ajax("/subscribe/checkout", {
      method: "post",
      data: { product_id: this.id },
    });
  }

  get amountLabel() {
    if (!this.currency || !this.amount_cents) {
      return null;
    }

    const amount = this.amount_cents / 100;
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currency,
    }).format(amount);
  }
}
