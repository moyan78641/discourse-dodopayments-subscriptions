import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-user-subscriptions">
      <h2>{{i18n "discourse_dodo_subscriptions.user.subscriptions.title"}}</h2>

      {{#if @controller.model.length}}
        <div class="dodo-user-subscriptions__table-wrap">
          <table class="table dodo-user-subscriptions__table">
            <thead>
              <tr>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.id"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.product"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.rate"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.status"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.current_period_end"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.cancel_at_period_end"
                  }}</th>
                <th>{{i18n
                    "discourse_dodo_subscriptions.user.subscriptions.created_at"
                  }}</th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.model as |subscription|}}
                <tr>
                  <td>{{subscription.id}}</td>
                  <td>{{subscription.productName}}</td>
                  <td>{{subscription.rateLabel}}</td>
                  <td>
                    <span class="dodo-user-subscriptions__status">
                      {{subscription.status}}
                    </span>
                  </td>
                  <td>{{subscription.currentPeriodEndLabel}}</td>
                  <td>{{subscription.cancelAtPeriodEndLabel}}</td>
                  <td>{{subscription.createdAtLabel}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <div class="alert alert-info dodo-user-subscriptions__empty">
          <p>{{i18n
              "discourse_dodo_subscriptions.user.subscriptions.empty"
            }}</p>
          <DButton
            @route="dodo-subscribe"
            @icon="credit-card"
            @label="discourse_dodo_subscriptions.user.subscriptions.subscribe"
            class="btn-primary"
          />
        </div>
      {{/if}}
    </div>
  </template>
);
