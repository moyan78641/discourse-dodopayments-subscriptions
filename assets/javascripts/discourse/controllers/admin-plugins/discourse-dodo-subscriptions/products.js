import Controller from "@ember/controller";
import { action } from "@ember/object";
import AdminDodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/admin-dodo-product";

export default class AdminPluginsDiscourseDodoSubscriptionsProductsController extends Controller {
  saving = false;

  @action
  addProduct() {
    this.model.pushObject(AdminDodoProduct.createEmpty());
  }

  @action
  saveProduct(product) {
    this.set("saving", true);
    product
      .save()
      .then((result) => {
        product.setProperties(result);
      })
      .finally(() => this.set("saving", false));
  }

  @action
  deleteProduct(product) {
    if (!product.id) {
      this.model.removeObject(product);
      return;
    }

    product.destroyRecord().then(() => this.model.removeObject(product));
  }
}
