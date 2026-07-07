import EmberObject, { computed } from "@ember/object";
import { ajax } from "discourse/lib/ajax";

export default class AdminDodoProduct extends EmberObject {
  static findAll() {
    return ajax("/subscribe/admin/products", { method: "get" }).then(
      (products) => products.map((product) => AdminDodoProduct.create(product))
    );
  }

  static createEmpty() {
    return AdminDodoProduct.create({
      active: true,
      repurchaseable: false,
      currency: "USD",
      recurring_interval: "month",
    });
  }

  @computed("amount_cents")
  get amount() {
    if (this.amount_cents === null || this.amount_cents === undefined) {
      return "";
    }

    return (Number(this.amount_cents) / 100).toFixed(2);
  }

  set amount(value) {
    const normalized = value?.toString().trim();

    if (!normalized) {
      this.set("amount_cents", null);
      return "";
    }

    const amount = Number.parseFloat(normalized.replace(",", "."));

    if (!Number.isNaN(amount)) {
      this.set("amount_cents", Math.round(amount * 100));
    }

    return value;
  }

  @computed("group_name")
  get groupNames() {
    return this.group_name ? [this.group_name] : [];
  }

  save() {
    const data = this.payload;
    const id = this.id;

    if (id) {
      return ajax(`/subscribe/admin/products/${id}`, {
        method: "patch",
        data,
      });
    }

    return ajax("/subscribe/admin/products", { method: "post", data });
  }

  destroyRecord() {
    return ajax(`/subscribe/admin/products/${this.id}`, { method: "delete" });
  }

  get payload() {
    return {
      external_id: this.external_id,
      name: this.name,
      description: this.description,
      group_name: this.group_name,
      active: this.active,
      repurchaseable: this.repurchaseable,
      amount_cents: this.amount_cents,
      currency: this.currency,
      recurring_interval: this.recurring_interval,
    };
  }
}
