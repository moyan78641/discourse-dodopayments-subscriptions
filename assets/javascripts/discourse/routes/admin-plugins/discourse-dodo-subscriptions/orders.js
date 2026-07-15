import Route from "@ember/routing/route";
import AdminDodoOrder from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/admin-dodo-order";

export default class AdminPluginsDiscourseDodoSubscriptionsOrdersRoute extends Route {
  model() {
    return AdminDodoOrder.findAll();
  }
}
