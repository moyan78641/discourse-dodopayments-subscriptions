import Route from "@ember/routing/route";
import DodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/dodo-product";

export default class DodoSubscribeIndexRoute extends Route {
  model() {
    return DodoProduct.findAll();
  }
}
