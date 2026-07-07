import Route from "@ember/routing/route";
import UserDodoSubscription from "discourse/plugins/discourse-dodopayments-subscriptions/discourse/models/user-dodo-subscription";

export default class UserBillingSubscriptionsRoute extends Route {
  model() {
    return UserDodoSubscription.findAll();
  }
}
