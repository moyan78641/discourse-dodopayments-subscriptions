import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Group from "discourse/models/group";
import AdminDodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/admin-dodo-product";
import { i18n } from "discourse-i18n";

export default class AdminPluginsDiscourseDodoSubscriptionsProductsController extends Controller {
  @service dialog;

  saving = false;
  groups = [];

  get currencies() {
    return [
      "USD",
      "CNY",
      "EUR",
      "GBP",
      "CAD",
      "AUD",
      "JPY",
      "HKD",
      "SGD",
      "INR",
      "BRL",
      "CHF",
      "SEK",
      "NZD",
    ];
  }

  get recurringIntervals() {
    return [
      {
        value: "month",
        label: i18n("discourse_dodo_subscriptions.intervals.month"),
      },
      {
        value: "quarter",
        label: i18n("discourse_dodo_subscriptions.intervals.quarter"),
      },
      {
        value: "half_year",
        label: i18n("discourse_dodo_subscriptions.intervals.half_year"),
      },
      {
        value: "year",
        label: i18n("discourse_dodo_subscriptions.intervals.year"),
      },
    ];
  }

  get billingTypes() {
    return [
      {
        value: "subscription",
        label: i18n(
          "discourse_dodo_subscriptions.admin.products.billing_types.subscription",
        ),
      },
      {
        value: "one_time",
        label: i18n(
          "discourse_dodo_subscriptions.admin.products.billing_types.one_time",
        ),
      },
    ];
  }

  loadGroups() {
    Group.findAll({ ignore_automatic: true }).then((groups) => {
      this.set("groups", groups);
    });
  }

  @action
  addProduct() {
    this.model.pushObject(AdminDodoProduct.createEmpty());
  }

  @action
  updateProductGroup(product, groupNames) {
    product.set("group_name", groupNames?.[0]);
  }

  @action
  updateProductCurrency(product, currency) {
    product.set("currency", currency);
  }

  @action
  updateProductInterval(product, interval) {
    product.set("recurring_interval", interval);
  }

  @action
  updateProductBillingType(product, billingType) {
    product.set("billing_type", billingType);
    if (billingType !== "one_time") {
      product.set("wechat_pay_enabled", false);
    }
  }

  @action
  preventFormSubmit(event) {
    event.preventDefault();
  }

  @action
  saveProduct(product) {
    this.set("saving", true);
    product
      .save()
      .then((result) => {
        product.setProperties(result);
      })
      .catch(popupAjaxError)
      .finally(() => this.set("saving", false));
  }

  @action
  deleteProduct(product) {
    if (!product.id) {
      this.model.removeObject(product);
      return;
    }

    this.dialog.confirm({
      message: i18n(
        "discourse_dodo_subscriptions.admin.products.delete_confirm",
      ),
      didConfirm: () => {
        product
          .destroyRecord()
          .then(() => this.model.removeObject(product))
          .catch(popupAjaxError);
      },
    });
  }
}
