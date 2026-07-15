import { Input, Textarea } from "@ember/component";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import RouteTemplate from "ember-route-template";
import GroupChooser from "discourse/select-kit/components/group-chooser";
import DButton from "discourse/ui-kit/d-button";
import DSelect from "discourse/ui-kit/d-select";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-admin-products">
      <div class="dodo-admin-products__header">
        <div>
          <h2>{{i18n "discourse_dodo_subscriptions.admin.products.title"}}</h2>
          <p>{{i18n "discourse_dodo_subscriptions.admin.products.help"}}</p>
        </div>
        <DButton
          @action={{@controller.addProduct}}
          @icon="plus"
          @label="discourse_dodo_subscriptions.admin.products.add"
          class="btn-primary"
        />
      </div>

      {{#each @controller.model as |product|}}
        <form
          class="dodo-admin-products__row"
          {{on "submit" @controller.preventFormSubmit}}
        >
          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.external_id"
              }}</span>
            <Input
              @value={{product.external_id}}
              placeholder="pdt_..."
              class="dodo-admin-products__input"
            />
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.name"
              }}</span>
            <Input @value={{product.name}} class="dodo-admin-products__input" />
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.plan_key"
              }}</span>
            <Input
              @value={{product.plan_key}}
              placeholder="members"
              class="dodo-admin-products__input"
            />
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.billing_type"
              }}</span>
            <DSelect
              @value={{product.billing_type}}
              @includeNone={{false}}
              @onChange={{fn @controller.updateProductBillingType product}}
              class="dodo-admin-products__select"
              as |select|
            >
              {{#each @controller.billingTypes as |billingType|}}
                <select.Option @value={{billingType.value}}>
                  {{billingType.label}}
                </select.Option>
              {{/each}}
            </DSelect>
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.group_name"
              }}</span>
            <GroupChooser
              @content={{@controller.groups}}
              @value={{product.groupNames}}
              @labelProperty="name"
              @valueProperty="name"
              @onChange={{fn @controller.updateProductGroup product}}
              @options={{hash maximum=1}}
              class="dodo-admin-products__group"
            />
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.amount"
              }}</span>
            <Input
              @value={{product.amount}}
              @type="number"
              min="0"
              step="0.01"
              class="dodo-admin-products__input"
            />
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.currency"
              }}</span>
            <DSelect
              @value={{product.currency}}
              @includeNone={{false}}
              @onChange={{fn @controller.updateProductCurrency product}}
              class="dodo-admin-products__select"
              as |select|
            >
              {{#each @controller.currencies as |currency|}}
                <select.Option @value={{currency}}>
                  {{currency}}
                </select.Option>
              {{/each}}
            </DSelect>
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.access_interval"
              }}</span>
            <DSelect
              @value={{product.recurring_interval}}
              @includeNone={{false}}
              @onChange={{fn @controller.updateProductInterval product}}
              class="dodo-admin-products__select"
              as |select|
            >
              {{#each @controller.recurringIntervals as |interval|}}
                <select.Option @value={{interval.value}}>
                  {{interval.label}}
                </select.Option>
              {{/each}}
            </DSelect>
          </label>

          <label class="dodo-admin-products__field">
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.position"
              }}</span>
            <Input
              @value={{product.position}}
              @type="number"
              min="0"
              step="1"
              class="dodo-admin-products__input"
            />
          </label>

          <label
            class="dodo-admin-products__field dodo-admin-products__field--wide"
          >
            <span>{{i18n
                "discourse_dodo_subscriptions.admin.products.description"
              }}</span>
            <Textarea
              @value={{product.description}}
              class="dodo-admin-products__description"
            />
          </label>

          <label class="dodo-admin-products__checkbox">
            <Input @type="checkbox" @checked={{product.active}} />
            {{i18n "discourse_dodo_subscriptions.admin.products.active"}}
          </label>
          <label class="dodo-admin-products__checkbox">
            <Input @type="checkbox" @checked={{product.repurchaseable}} />
            {{i18n
              "discourse_dodo_subscriptions.admin.products.repurchaseable"
            }}
          </label>
          {{#if product.isOneTime}}
            <label class="dodo-admin-products__checkbox">
              <Input @type="checkbox" @checked={{product.wechat_pay_enabled}} />
              {{i18n
                "discourse_dodo_subscriptions.admin.products.wechat_pay_enabled"
              }}
            </label>
          {{/if}}

          <div class="dodo-admin-products__actions">
            <DButton
              @action={{fn @controller.saveProduct product}}
              @disabled={{@controller.saving}}
              @icon="check"
              @label="discourse_dodo_subscriptions.admin.products.save"
              class="btn-primary"
            />
            <DButton
              @action={{fn @controller.deleteProduct product}}
              @icon="trash-can"
              @label="discourse_dodo_subscriptions.admin.products.delete"
              class="btn-danger"
            />
          </div>
        </form>
      {{/each}}
    </div>
  </template>,
);
