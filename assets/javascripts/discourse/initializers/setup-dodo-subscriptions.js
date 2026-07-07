import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "setup-dodo-subscriptions",
  initialize(container) {
    withPluginApi((api) => {
      const siteSettings = container.lookup("service:site-settings");

      if (siteSettings.discourse_dodo_subscriptions_extra_nav_subscribe) {
        api.addNavigationBarItem({
          name: "dodo-subscribe",
          displayName: i18n("discourse_dodo_subscriptions.navigation.subscribe"),
          href: "/subscribe",
        });
      }

      const user = api.getCurrentUser();
      if (user) {
        api.addQuickAccessProfileItem({
          icon: "credit-card",
          href: `/u/${user.username}/billing/subscriptions`,
          content: i18n(
            "discourse_dodo_subscriptions.navigation.subscriptions"
          ),
        });
      }
    });
  },
};
