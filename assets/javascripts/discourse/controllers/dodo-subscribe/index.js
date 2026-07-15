import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { i18n } from "discourse-i18n";

const INTERVAL_MONTHS = {
  month: 1,
  quarter: 3,
  half_year: 6,
  year: 12,
};

const INTERVAL_ORDER = {
  month: 1,
  quarter: 2,
  half_year: 3,
  year: 4,
};

const BILLING_TYPE_ORDER = {
  subscription: 1,
  one_time: 2,
};

export default class DodoSubscribeIndexController extends Controller {
  @service currentUser;
  @service dialog;
  @service router;

  @tracked loadingProductId = null;
  @tracked selectedIntervals = {};
  @tracked selectedBillingType = null;

  get availableBillingTypes() {
    return [
      ...new Set((this.model || []).map((product) => product.billing_type)),
    ]
      .filter(Boolean)
      .sort(
        (a, b) => (BILLING_TYPE_ORDER[a] || 99) - (BILLING_TYPE_ORDER[b] || 99),
      );
  }

  get billingTypes() {
    return this.availableBillingTypes.map((billingType) => ({
      value: billingType,
      selected: billingType === this.activeBillingType,
      label: i18n(
        `discourse_dodo_subscriptions.subscribe.billing_types.${billingType}`,
      ),
    }));
  }

  get hasMultipleBillingTypes() {
    return this.billingTypes.length > 1;
  }

  get activeBillingType() {
    const availableTypes = this.availableBillingTypes;
    return availableTypes.includes(this.selectedBillingType)
      ? this.selectedBillingType
      : availableTypes[0] || "subscription";
  }

  get productGroups() {
    const groups = new Map();

    (this.model || [])
      .filter((product) => product.billing_type === this.activeBillingType)
      .forEach((product) => {
        const key =
          product.plan_key || product.group_name || product.name || product.id;
        if (!groups.has(key)) {
          groups.set(key, []);
        }
        groups.get(key).push(product);
      });

    return Array.from(groups.entries()).map(([key, products]) => {
      const modeProducts = products.sort(
        (a, b) =>
          (INTERVAL_ORDER[a.recurring_interval] || 99) -
          (INTERVAL_ORDER[b.recurring_interval] || 99),
      );
      const selectedInterval =
        this.selectedIntervals[key] || modeProducts[0]?.recurring_interval;
      const selectedProduct =
        modeProducts.find(
          (product) => product.recurring_interval === selectedInterval,
        ) || modeProducts[0];
      const selectedPlan = this.buildPlan(
        selectedProduct,
        this.monthlyPriceFor(modeProducts, selectedProduct),
      );

      return {
        key,
        name: products[0]?.name || selectedProduct?.name,
        description: products[0]?.description || selectedProduct?.description,
        selectedPlan,
        hasMultiplePlans: modeProducts.length > 1,
        plans: modeProducts.map((product) => {
          const plan = this.buildPlan(
            product,
            this.monthlyPriceFor(modeProducts, product),
          );
          plan.selected = product.id === selectedProduct?.id;
          return plan;
        }),
      };
    });
  }

  monthlyPriceFor(products, selectedProduct) {
    return products.find(
      (product) =>
        product.recurring_interval === "month" &&
        product.currency === selectedProduct?.currency,
    )?.amount_cents;
  }

  buildPlan(product, monthlyPrice) {
    const months = INTERVAL_MONTHS[product?.recurring_interval] || 1;
    const monthlyEquivalentCents =
      months > 1 && product?.amount_cents
        ? Math.round(product.amount_cents / months)
        : null;

    let savingsLabel = null;
    if (
      monthlyPrice &&
      monthlyEquivalentCents &&
      monthlyEquivalentCents < monthlyPrice
    ) {
      const percent = Math.round(
        (1 - monthlyEquivalentCents / monthlyPrice) * 100,
      );
      if (percent > 0) {
        savingsLabel = i18n(
          "discourse_dodo_subscriptions.subscribe.save_percent",
          { percent },
        );
      }
    }

    const intervalKey =
      product?.billing_type === "one_time" ? "durations" : "intervals";

    return {
      product,
      id: product?.id,
      interval: product?.recurring_interval,
      intervalLabel: i18n(
        `discourse_dodo_subscriptions.${intervalKey}.${
          product?.recurring_interval || "month"
        }`,
      ),
      amountLabel: product?.amountLabel,
      monthlyEquivalentLabel: monthlyEquivalentCents
        ? i18n("discourse_dodo_subscriptions.subscribe.monthly_equivalent", {
            amount: product.formatAmount(monthlyEquivalentCents),
          })
        : null,
      savingsLabel,
      subscribed:
        product?.billing_type === "subscription" && product?.subscribed,
      conflict: product?.conflict,
      billingType: product?.billing_type,
      paymentNote: i18n(
        `discourse_dodo_subscriptions.subscribe.payment_notes.${
          product?.billing_type || "subscription"
        }`,
      ),
      supportsWechat: product?.wechat_pay_enabled,
      loading: this.loadingProductId === product?.id,
    };
  }

  @action
  selectBillingType(billingType) {
    this.selectedBillingType = billingType;
  }

  @action
  selectPlan(groupKey, interval) {
    this.selectedIntervals = {
      ...this.selectedIntervals,
      [groupKey]: interval,
    };
  }

  @action
  checkout(product) {
    if (!this.currentUser) {
      this.dialog.alert(
        i18n("discourse_dodo_subscriptions.subscribe.login_required"),
      );
      return;
    }

    if (product.conflict) {
      this.dialog.alert(
        i18n(
          `discourse_dodo_subscriptions.subscribe.conflicts.${product.conflict}`,
        ),
      );
      return;
    }

    this.loadingProductId = product.id;

    product
      .checkout()
      .then((result) => {
        if (result.subscribed) {
          this.router.transitionTo("dodo-subscribe.success");
        } else if (result.conflict) {
          this.dialog.alert(
            i18n(
              `discourse_dodo_subscriptions.subscribe.conflicts.${result.conflict}`,
            ),
          );
          this.loadingProductId = null;
        } else if (result.pending) {
          this.dialog.alert(
            i18n("discourse_dodo_subscriptions.subscribe.pending_checkout"),
          );
          this.loadingProductId = null;
        } else if (result.checkout_url) {
          window.location.href = result.checkout_url;
        } else {
          this.dialog.alert(
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error"),
          );
          this.loadingProductId = null;
        }
      })
      .catch((error) => {
        this.dialog.alert(
          error?.jqXHR?.responseJSON?.errors?.[0] ||
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error"),
        );
        this.loadingProductId = null;
      });
  }
}
