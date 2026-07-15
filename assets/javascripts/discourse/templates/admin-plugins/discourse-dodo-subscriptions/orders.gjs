import { Input, Textarea } from "@ember/component";
import { concat, fn } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import DSelect from "discourse/ui-kit/d-select";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-admin-orders">
      <div class="dodo-admin-orders__summary">
        <div>
          <span>{{i18n
              "discourse_dodo_subscriptions.admin.orders.summary.active"
            }}</span>
          <strong>{{@controller.model.summary.active}}</strong>
        </div>
        <div>
          <span>{{i18n
              "discourse_dodo_subscriptions.admin.orders.summary.expiring"
            }}</span>
          <strong>{{@controller.model.summary.expiring_soon}}</strong>
        </div>
        <div>
          <span>{{i18n
              "discourse_dodo_subscriptions.admin.orders.summary.expired"
            }}</span>
          <strong>{{@controller.model.summary.expired}}</strong>
        </div>
        <div>
          <span>{{i18n
              "discourse_dodo_subscriptions.admin.orders.summary.manual"
            }}</span>
          <strong>{{@controller.model.summary.manual}}</strong>
        </div>
        <div>
          <span>{{i18n
              "discourse_dodo_subscriptions.admin.orders.summary.subscriptions"
            }}</span>
          <strong>{{@controller.model.summary.subscriptions}}</strong>
        </div>
      </div>

      <div class="dodo-admin-order-filters">
        <Input
          @value={{@controller.filterQuery}}
          placeholder={{i18n
            "discourse_dodo_subscriptions.admin.orders.search_placeholder"
          }}
        />
        <DSelect
          @value={{@controller.filterStatus}}
          @includeNone={{true}}
          @onChange={{@controller.setFilterStatus}}
          as |select|
        >
          {{#each @controller.statusOptions as |status|}}
            <select.Option
              @value={{status.value}}
            >{{status.label}}</select.Option>
          {{/each}}
        </DSelect>
        <DSelect
          @value={{@controller.filterSource}}
          @includeNone={{true}}
          @onChange={{@controller.setFilterSource}}
          as |select|
        >
          {{#each @controller.sourceOptions as |source|}}
            <select.Option
              @value={{source.value}}
            >{{source.label}}</select.Option>
          {{/each}}
        </DSelect>
        <DButton
          @action={{@controller.reloadOrders}}
          @icon="search"
          @label="discourse_dodo_subscriptions.admin.orders.search"
        />
      </div>

      <section class="dodo-admin-manual-order">
        <div class="dodo-admin-section-heading">
          <h2>{{i18n
              "discourse_dodo_subscriptions.admin.orders.manual_title"
            }}</h2>
          <p>{{i18n
              "discourse_dodo_subscriptions.admin.orders.manual_help"
            }}</p>
        </div>

        <div class="dodo-admin-manual-order__fields">
          <label>
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.user"
              }}</span>
            <Input @value={{@controller.usernameOrEmail}} />
          </label>
          <label>
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.product"
              }}</span>
            <DSelect
              @value={{@controller.selectedProductId}}
              @onChange={{@controller.selectProduct}}
              as |select|
            >
              {{#each @controller.model.products as |product|}}
                <select.Option @value={{product.id}}>
                  {{product.name}}
                  -
                  {{i18n
                    (concat
                      "discourse_dodo_subscriptions.intervals."
                      product.recurring_interval
                    )
                  }}
                </select.Option>
              {{/each}}
            </DSelect>
          </label>
          <label>
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.duration_days"
              }}</span>
            <Input @type="number" min="1" @value={{@controller.durationDays}} />
          </label>
          <label>
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.amount"
              }}</span>
            <Input
              @type="number"
              min="0"
              step="0.01"
              @value={{@controller.amount}}
            />
          </label>
          <label>
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.payment_method"
              }}</span>
            <Input @value={{@controller.paymentMethod}} />
          </label>
          <label class="dodo-admin-manual-order__note">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.orders.note"
              }}</span>
            <Textarea @value={{@controller.note}} />
          </label>
          <label class="dodo-admin-products__checkbox">
            <Input @type="checkbox" @checked={{@controller.notifyUser}} />
            {{i18n "discourse_dodo_subscriptions.admin.orders.notify_user"}}
          </label>
        </div>

        <DButton
          @action={{@controller.createManualOrder}}
          @isLoading={{@controller.saving}}
          @icon="plus"
          @label="discourse_dodo_subscriptions.admin.orders.create"
          class="btn-primary"
        />
      </section>

      <section class="dodo-admin-order-list">
        <div class="dodo-admin-section-heading">
          <h2>{{i18n "discourse_dodo_subscriptions.admin.orders.title"}}</h2>
        </div>

        {{#each @controller.model.orders as |order|}}
          <article class="dodo-admin-order">
            <div class="dodo-admin-order__identity">
              <div>
                <strong>{{order.user.username}}</strong>
                <span>{{order.user.email}}</span>
              </div>
              <span
                class="dodo-admin-order__status dodo-admin-order__status--{{order.status}}"
              >
                {{order.statusLabel}}
              </span>
            </div>

            <dl class="dodo-admin-order__details">
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.product"
                  }}</dt><dd>{{order.product.name}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.source"
                  }}</dt><dd>{{order.sourceLabel}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.amount"
                  }}</dt><dd>{{order.amountLabel}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.expires_at"
                  }}</dt><dd>{{order.expiresAtLabel}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.payment_method"
                  }}</dt><dd>{{order.payment_method}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.external_id"
                  }}</dt><dd><code>{{order.external_id}}</code></dd></div>
            </dl>

            <div class="dodo-admin-order__operations">
              <Input
                @value={{order.operationNote}}
                placeholder={{i18n
                  "discourse_dodo_subscriptions.admin.orders.operation_note"
                }}
              />
              <Input
                @type="number"
                min="1"
                @value={{order.extensionDays}}
                placeholder={{i18n
                  "discourse_dodo_subscriptions.admin.orders.days"
                }}
              />
              <DButton
                @action={{fn @controller.extendOrder order}}
                @icon="plus"
                @label="discourse_dodo_subscriptions.admin.orders.extend"
              />
              <Input @type="datetime-local" @value={{order.newExpiry}} />
              <DButton
                @action={{fn @controller.setExpiry order}}
                @icon="check"
                @label="discourse_dodo_subscriptions.admin.orders.set_expiry"
              />
              <DButton
                @action={{fn @controller.revokeOrder order}}
                @icon="trash-can"
                @label="discourse_dodo_subscriptions.admin.orders.revoke"
                class="btn-danger"
              />
            </div>
          </article>
        {{else}}
          <div class="alert alert-info">
            {{i18n "discourse_dodo_subscriptions.admin.orders.empty"}}
          </div>
        {{/each}}
      </section>

      <section class="dodo-admin-order-list">
        <div class="dodo-admin-section-heading">
          <h2>{{i18n
              "discourse_dodo_subscriptions.admin.orders.subscriptions_title"
            }}</h2>
        </div>

        {{#each @controller.model.subscriptions as |subscription|}}
          <article class="dodo-admin-order">
            <div class="dodo-admin-order__identity">
              <div>
                <strong>{{subscription.user.username}}</strong>
                <span>{{subscription.user.email}}</span>
              </div>
              <span
                class="dodo-admin-order__status dodo-admin-order__status--{{subscription.status}}"
              >
                {{subscription.statusLabel}}
              </span>
            </div>
            <dl class="dodo-admin-order__details">
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.product"
                  }}</dt><dd>{{subscription.product.name}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.next_billing"
                  }}</dt><dd>{{subscription.currentPeriodEndLabel}}</dd></div>
              <div><dt>{{i18n
                    "discourse_dodo_subscriptions.admin.orders.external_id"
                  }}</dt><dd><code
                  >{{subscription.external_id}}</code></dd></div>
            </dl>
          </article>
        {{else}}
          <div class="alert alert-info">
            {{i18n
              "discourse_dodo_subscriptions.admin.orders.no_subscriptions"
            }}
          </div>
        {{/each}}
      </section>
    </div>
  </template>,
);
