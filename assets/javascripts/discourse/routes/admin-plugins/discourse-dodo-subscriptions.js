import Route from "@ember/routing/route";
import { service } from "@ember/service";

export default class AdminPluginsDiscourseDodoSubscriptionsRoute extends Route {
  @service router;

  beforeModel(transition) {
    if (
      transition.to.name === "adminPlugins.discourse-dodo-subscriptions" ||
      transition.to.name === "adminPlugins.discourse-dodo-subscriptions.index"
    ) {
      this.router.transitionTo("adminPlugins.discourse-dodo-subscriptions.products");
    }
  }
}
