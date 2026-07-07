import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import RouteTemplate from "ember-route-template";
import htmlSafe from "discourse/helpers/html-safe";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    {{#if @controller.productGroups.length}}
      <div class="dodo-product-list">
        {{#each @controller.productGroups as |group|}}
          <article class="dodo-product-list__item">
            {{#if group.hasMultiplePlans}}
              <div class="dodo-product-list__plans">
                {{#each group.plans as |plan|}}
                  <button
                    type="button"
                    aria-pressed={{if plan.selected "true" "false"}}
                    class="dodo-plan-toggle {{if plan.selected 'is-selected'}}"
                    {{on "click" (fn @controller.selectPlan group.key plan.interval)}}
                  >
                    <span>{{plan.intervalLabel}}</span>
                    {{#if plan.savingsLabel}}
                      <small>{{plan.savingsLabel}}</small>
                    {{/if}}
                  </button>
                {{/each}}
              </div>
            {{/if}}

            <div class="dodo-product-list__content">
              <div>
                <h2>{{group.name}}</h2>
                {{#if group.description}}
                  <div class="dodo-product-list__description">
                    {{htmlSafe group.description}}
                  </div>
                {{/if}}
              </div>

              <div class="dodo-product-list__purchase">
                {{#if group.selectedPlan.amountLabel}}
                  <div class="dodo-product-list__price-row">
                    <p class="dodo-product-list__price">
                      {{group.selectedPlan.amountLabel}}
                    </p>

                    {{#if group.selectedPlan.savingsLabel}}
                      <span class="dodo-product-list__saving">
                        {{group.selectedPlan.savingsLabel}}
                      </span>
                    {{/if}}
                  </div>
                {{/if}}

                <p class="dodo-product-list__interval">
                  {{group.selectedPlan.intervalLabel}}
                </p>

                {{#if group.selectedPlan.monthlyEquivalentLabel}}
                  <p class="dodo-product-list__monthly">
                    {{group.selectedPlan.monthlyEquivalentLabel}}
                  </p>
                {{/if}}

                {{#if group.selectedPlan.subscribed}}
                  <p class="dodo-product-list__subscribed">
                    {{i18n "discourse_dodo_subscriptions.subscribe.already_subscribed"}}
                  </p>
                {{else}}
                  <DButton
                    @action={{fn @controller.checkout group.selectedPlan.product}}
                    @isLoading={{group.selectedPlan.loading}}
                    @icon="credit-card"
                    @label="discourse_dodo_subscriptions.subscribe.checkout"
                    class="btn-primary dodo-product-list__button"
                  />
                {{/if}}
              </div>
            </div>
          </article>
        {{/each}}
      </div>
    {{else}}
      <p>{{i18n "discourse_dodo_subscriptions.subscribe.no_products"}}</p>
    {{/if}}
  </template>
);
