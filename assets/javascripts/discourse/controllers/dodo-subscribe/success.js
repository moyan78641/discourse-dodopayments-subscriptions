import Controller from "@ember/controller";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";

export default class DodoSubscribeSuccessController extends Controller {
  @service currentUser;

  get billingUrl() {
    if (!this.currentUser?.username) {
      return getURL("/subscribe");
    }

    return getURL(`/u/${this.currentUser.username}/billing/subscriptions`);
  }
}
