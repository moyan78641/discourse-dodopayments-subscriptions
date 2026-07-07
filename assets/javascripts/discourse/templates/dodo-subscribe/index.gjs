import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import htmlSafe from "discourse/helpers/html-safe";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    {{#if @controller.model.length}}
      <div class="dodo-product-list">
        {{#each @controller.model as |product|}}
          <article class="dodo-product-list__item">
            <h2>{{product.name}}</h2>
            <div class="dodo-product-list__description">
              {{htmlSafe product.description}}
            </div>

            {{#if product.amountLabel}}
              <p class="dodo-product-list__price">
                {{product.amountLabel}}
              </p>
            {{/if}}

            <LinkTo
              @route="dodo-subscribe.show"
              @model={{product.id}}
              class="btn btn-primary"
            >
              {{i18n "discourse_dodo_subscriptions.subscribe.checkout"}}
            </LinkTo>
          </article>
        {{/each}}
      </div>
    {{else}}
      <p>{{i18n "discourse_dodo_subscriptions.subscribe.no_products"}}</p>
    {{/if}}
  </template>
);
