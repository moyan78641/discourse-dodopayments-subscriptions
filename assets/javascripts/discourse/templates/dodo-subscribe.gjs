import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="container dodo-subscriptions">
      <div class="dodo-subscriptions__header">
        <h1>{{i18n "discourse_dodo_subscriptions.subscribe.title"}}</h1>
      </div>

      {{outlet}}
    </div>
  </template>,
);
