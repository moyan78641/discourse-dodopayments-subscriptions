import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class DodoSubscribeShowController extends Controller {
  @service currentUser;
  @service dialog;
  @service router;

  loading = false;

  @action
  checkout() {
    if (!this.currentUser) {
      this.dialog.alert(
        i18n("discourse_dodo_subscriptions.subscribe.login_required")
      );
      return;
    }

    this.set("loading", true);

    this.model
      .checkout()
      .then((result) => {
        if (result.subscribed) {
          this.router.transitionTo("dodo-subscribe.success");
        } else if (result.checkout_url) {
          window.location.href = result.checkout_url;
        } else {
          this.dialog.alert(
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error")
          );
          this.set("loading", false);
        }
      })
      .catch((error) => {
        this.dialog.alert(
          error?.jqXHR?.responseJSON?.errors?.[0] ||
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error")
        );
        this.set("loading", false);
      });
  }
}
