import Route from "@ember/routing/route";
import AdminDodoProduct from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/admin-dodo-product";

export default class AdminPluginsDiscourseDodoSubscriptionsProductsRoute extends Route {
  model() {
    return AdminDodoProduct.findAll();
  }
}
