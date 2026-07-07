import Route from "@ember/routing/route";
import DodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/dodo-product";

export default class DodoSubscribeShowRoute extends Route {
  model(params) {
    return DodoProduct.find(params["product-id"]);
  }
}
