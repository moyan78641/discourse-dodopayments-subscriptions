import Route from "@ember/routing/route";
import { service } from "@ember/service";

export default class UserBillingIndexRoute extends Route {
  @service router;

  redirect() {
    this.router.transitionTo("user.billing.subscriptions");
  }
}
