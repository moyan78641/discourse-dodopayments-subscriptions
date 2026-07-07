import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import htmlSafe from "discourse/helpers/html-safe";
import loadingSpinner from "discourse/helpers/loading-spinner";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <section class="dodo-product">
      <div class="dodo-product__details">
        <h2>{{@controller.model.name}}</h2>
        <div class="dodo-product__description">
          {{htmlSafe @controller.model.description}}
        </div>
      </div>

      <div class="dodo-product__checkout">
        {{#if @controller.model.amountLabel}}
          <p class="dodo-product__price">{{@controller.model.amountLabel}}</p>
        {{/if}}

        {{#if @controller.model.subscribed}}
          <p>{{i18n "discourse_dodo_subscriptions.subscribe.already_subscribed"}}</p>
        {{else if @controller.loading}}
          {{loadingSpinner}}
        {{else}}
          <DButton
            @action={{@controller.checkout}}
            class="btn-primary"
            @label="discourse_dodo_subscriptions.subscribe.checkout"
          />
        {{/if}}
      </div>
    </section>
  </template>
);
