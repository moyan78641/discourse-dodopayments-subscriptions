import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-admin-shell">
      <nav
        class="dodo-admin-tabs"
        aria-label={{i18n
          "discourse_dodo_subscriptions.admin.navigation.label"
        }}
      >
        <LinkTo @route="adminPlugins.discourse-dodo-subscriptions.products">
          {{i18n "discourse_dodo_subscriptions.admin.navigation.products"}}
        </LinkTo>
        <LinkTo @route="adminPlugins.discourse-dodo-subscriptions.orders">
          {{i18n "discourse_dodo_subscriptions.admin.navigation.orders"}}
        </LinkTo>
      </nav>
      {{outlet}}
    </div>
  </template>,
);
