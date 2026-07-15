import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { trustHTML } from "@ember/template";
import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    {{#if @controller.hasMultipleBillingTypes}}
      <div
        class="dodo-billing-toggle dodo-subscribe__billing-tabs"
        role="tablist"
      >
        {{#each @controller.billingTypes as |billingType|}}
          <button
            type="button"
            role="tab"
            aria-selected={{if billingType.selected "true" "false"}}
            class="dodo-billing-toggle__option
              {{if billingType.selected 'is-selected'}}"
            {{on "click" (fn @controller.selectBillingType billingType.value)}}
          >
            {{billingType.label}}
          </button>
        {{/each}}
      </div>
    {{/if}}

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
                    {{on
                      "click"
                      (fn @controller.selectPlan group.key plan.interval)
                    }}
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
                    {{trustHTML group.description}}
                  </div>
                {{/if}}
                <div class="dodo-payment-note">
                  <span>{{group.selectedPlan.paymentNote}}</span>
                  {{#if group.selectedPlan.supportsWechat}}
                    <strong>{{i18n
                        "discourse_dodo_subscriptions.subscribe.wechat_supported"
                      }}</strong>
                  {{/if}}
                </div>
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
                    {{i18n
                      "discourse_dodo_subscriptions.subscribe.already_subscribed"
                    }}
                  </p>
                {{else if group.selectedPlan.conflict}}
                  <p class="dodo-product-list__conflict">
                    {{i18n
                      (concat
                        "discourse_dodo_subscriptions.subscribe.conflicts."
                        group.selectedPlan.conflict
                      )
                    }}
                  </p>
                {{else}}
                  <DButton
                    @action={{fn
                      @controller.checkout
                      group.selectedPlan.product
                    }}
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
  </template>,
);
