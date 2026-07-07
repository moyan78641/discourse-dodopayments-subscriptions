import Route from "@ember/routing/route";
import { service } from "@ember/service";
import DodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/dodo-product";

export default class DodoSubscribeIndexRoute extends Route {
  @service router;

  model() {
    return DodoProduct.findAll();
  }

  afterModel(products) {
    if (products.length === 1) {
      this.router.transitionTo("dodo-subscribe.show", products[0].id);
    }
  }
}
