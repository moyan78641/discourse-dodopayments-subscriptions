import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <section class="dodo-subscriptions__success">
      <h2>{{i18n "discourse_dodo_subscriptions.subscribe.success_title"}}</h2>
      <p>{{i18n "discourse_dodo_subscriptions.subscribe.success_body"}}</p>
    </section>
  </template>
);
