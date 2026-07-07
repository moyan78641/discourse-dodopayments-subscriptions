import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <section class="dodo-subscriptions__success">
      <h2>{{i18n "discourse_dodo_subscriptions.subscribe.success_title"}}</h2>
      <p>{{i18n "discourse_dodo_subscriptions.subscribe.success_body"}}</p>
      <DButton
        @href={{@controller.billingUrl}}
        @icon="credit-card"
        @label="discourse_dodo_subscriptions.subscribe.view_subscriptions"
        class="btn-primary"
      />
    </section>
  </template>
);
