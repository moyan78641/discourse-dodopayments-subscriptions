import { Input, Textarea } from "@ember/component";
import { fn } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="dodo-admin-products">
      <div class="dodo-admin-products__header">
        <h2>{{i18n "discourse_dodo_subscriptions.admin.products.title"}}</h2>
        <DButton
          @action={{@controller.addProduct}}
          @icon="plus"
          @label="discourse_dodo_subscriptions.admin.products.add"
          class="btn-primary"
        />
      </div>

      {{#each @controller.model as |product|}}
        <form class="dodo-admin-products__row">
          <Input
            @value={{product.external_id}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.external_id"}}
            class="dodo-admin-products__input"
          />
          <Input
            @value={{product.name}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.name"}}
            class="dodo-admin-products__input"
          />
          <Input
            @value={{product.group_name}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.group_name"}}
            class="dodo-admin-products__input"
          />
          <Input
            @value={{product.amount_cents}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.amount_cents"}}
            class="dodo-admin-products__input"
          />
          <Input
            @value={{product.currency}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.currency"}}
            class="dodo-admin-products__input"
          />
          <Input
            @value={{product.recurring_interval}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.recurring_interval"}}
            class="dodo-admin-products__input"
          />
          <Textarea
            @value={{product.description}}
            placeholder={{i18n "discourse_dodo_subscriptions.admin.products.description"}}
            class="dodo-admin-products__description"
          />

          <label class="dodo-admin-products__checkbox">
            <Input @type="checkbox" @checked={{product.active}} />
            {{i18n "discourse_dodo_subscriptions.admin.products.active"}}
          </label>
          <label class="dodo-admin-products__checkbox">
            <Input @type="checkbox" @checked={{product.repurchaseable}} />
            {{i18n "discourse_dodo_subscriptions.admin.products.repurchaseable"}}
          </label>

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
  </template>
);
