import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-user-subscriptions">
      <header class="dodo-user-subscriptions__header">
        <h2>{{i18n
            "discourse_dodo_subscriptions.user.subscriptions.title"
          }}</h2>
      </header>

      {{#if @controller.model.length}}
        <div class="dodo-user-subscriptions__list">
          {{#each @controller.model as |subscription|}}
            <article class="dodo-user-subscription">
              <div class="dodo-user-subscription__top">
                <div>
                  <span class="dodo-user-subscription__label">
                    {{i18n
                      "discourse_dodo_subscriptions.user.subscriptions.plan"
                    }}
                  </span>
                  <h3>{{subscription.productName}}</h3>
                </div>

                <span class={{subscription.statusClassName}}>
                  {{subscription.statusLabel}}
                </span>
              </div>

              <dl class="dodo-user-subscription__details">
                <div>
                  <dt>{{i18n
                      "discourse_dodo_subscriptions.user.subscriptions.access_type"
                    }}</dt>
                  <dd>{{subscription.accessTypeLabel}}</dd>
                </div>
                <div>
                  <dt>{{subscription.periodEndTitle}}</dt>
                  <dd>{{subscription.currentPeriodEndLabel}}</dd>
                </div>
                <div>
                  <dt>{{i18n
                      "discourse_dodo_subscriptions.user.subscriptions.started_at"
                    }}</dt>
                  <dd>{{subscription.createdAtLabel}}</dd>
                </div>
                <div>
                  <dt>{{i18n
                      "discourse_dodo_subscriptions.user.subscriptions.renewal"
                    }}</dt>
                  <dd>{{subscription.renewalLabel}}</dd>
                </div>
                <div>
                  <dt>{{i18n
                      "discourse_dodo_subscriptions.user.subscriptions.price"
                    }}</dt>
                  <dd>{{subscription.rateLabel}}</dd>
                </div>
              </dl>

              <div class="dodo-user-subscription__reference">
                <span>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.id"
                  }}</span>
                <code>{{subscription.id}}</code>
              </div>

              {{#if subscription.hasDuplicateSubscriptions}}
                <p class="dodo-user-subscription__notice">
                  {{subscription.duplicateSubscriptionNotice}}
                </p>
              {{/if}}
            </article>
          {{/each}}
        </div>
      {{else}}
        <div class="alert alert-info dodo-user-subscriptions__empty">
          <p>{{i18n
              "discourse_dodo_subscriptions.user.subscriptions.empty"
            }}</p>
        </div>
      {{/if}}
    </div>
  </template>,
);
