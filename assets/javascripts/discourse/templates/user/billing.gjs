import RouteTemplate from "ember-route-template";
import bodyClass from "discourse/helpers/body-class";

export default RouteTemplate(
  <template>
    {{bodyClass "user-billing-page"}}

    <section class="user-content dodo-user-billing" id="user-content">
      {{outlet}}
    </section>
  </template>,
);
