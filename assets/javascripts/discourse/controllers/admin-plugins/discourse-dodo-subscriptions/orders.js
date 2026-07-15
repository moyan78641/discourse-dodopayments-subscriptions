import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import AdminDodoOrder from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/admin-dodo-order";
import { i18n } from "discourse-i18n";

export default class AdminPluginsDiscourseDodoSubscriptionsOrdersController extends Controller {
  @service dialog;

  usernameOrEmail = "";
  selectedProductId = null;
  durationDays = null;
  amount = null;
  paymentMethod = "manual";
  note = "";
  notifyUser = true;
  saving = false;
  filterQuery = "";
  filterStatus = null;
  filterSource = null;

  get orderStatuses() {
    return ["succeeded", "expired", "revoked", "refunded"];
  }

  get statusOptions() {
    return this.orderStatuses.map((status) => ({
      value: status,
      label: i18n(
        `discourse_dodo_subscriptions.admin.orders.statuses.${status}`,
      ),
    }));
  }

  get sourceOptions() {
    return ["dodo", "manual"].map((source) => ({
      value: source,
      label: i18n(
        `discourse_dodo_subscriptions.admin.orders.sources.${source}`,
      ),
    }));
  }

  @action
  selectProduct(productId) {
    this.set("selectedProductId", productId);
  }

  @action
  setFilterStatus(status) {
    this.set("filterStatus", status);
  }

  @action
  setFilterSource(source) {
    this.set("filterSource", source);
  }

  @action
  reloadOrders() {
    AdminDodoOrder.findAll({
      q: this.filterQuery || null,
      status: this.filterStatus || null,
      source: this.filterSource || null,
    })
      .then((model) => this.set("model", model))
      .catch(popupAjaxError);
  }

  @action
  createManualOrder() {
    if (!this.usernameOrEmail || !this.selectedProductId) {
      this.dialog.alert(
        i18n("discourse_dodo_subscriptions.admin.orders.missing_fields"),
      );
      return;
    }

    const product = this.model.products.find(
      (item) => item.id === Number(this.selectedProductId),
    );
    const amountNumber = Number.parseFloat(this.amount);
    this.set("saving", true);

    AdminDodoOrder.createManual({
      username_or_email: this.usernameOrEmail,
      product_id: this.selectedProductId,
      duration_days: this.durationDays || null,
      amount_cents: Number.isNaN(amountNumber)
        ? null
        : Math.round(amountNumber * 100),
      currency: product?.currency,
      payment_method: this.paymentMethod,
      note: this.note,
      notify_user: this.notifyUser,
    })
      .then((result) => {
        this.model.orders.unshiftObject(AdminDodoOrder.create(result));
        this.setProperties({
          usernameOrEmail: "",
          durationDays: null,
          amount: null,
          note: "",
        });
      })
      .catch(popupAjaxError)
      .finally(() => this.set("saving", false));
  }

  @action
  extendOrder(order) {
    order
      .updateOperation({
        operation: "extend",
        duration_days: order.extensionDays || null,
        note: order.operationNote,
        notify_user: true,
      })
      .then((result) => {
        if (result.id !== order.id) {
          this.model.orders.unshiftObject(AdminDodoOrder.create(result));
        }
      })
      .catch(popupAjaxError);
  }

  @action
  setExpiry(order) {
    order
      .updateOperation({
        operation: "set_expiry",
        expires_at: order.newExpiry,
        note: order.operationNote,
        notify_user: false,
      })
      .catch(popupAjaxError);
  }

  @action
  revokeOrder(order) {
    this.dialog.confirm({
      message: i18n("discourse_dodo_subscriptions.admin.orders.revoke_confirm"),
      didConfirm: () =>
        order
          .updateOperation({
            operation: "revoke",
            note: order.operationNote,
            notify_user: false,
          })
          .catch(popupAjaxError),
    });
  }
}
