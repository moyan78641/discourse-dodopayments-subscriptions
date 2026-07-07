import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
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

export default class DodoSubscribeIndexController extends Controller {
  @service currentUser;
  @service dialog;
  @service router;

  @tracked loadingProductId = null;
  @tracked selectedIntervals = {};

  get productGroups() {
    const groups = new Map();

    (this.model || []).forEach((product) => {
      const key = product.name || product.id;
      if (!groups.has(key)) {
        groups.set(key, []);
      }
      groups.get(key).push(product);
    });

    return Array.from(groups.entries()).map(([key, products]) => {
      const sortedProducts = [...products].sort((a, b) => {
        return (
          (INTERVAL_ORDER[a.recurring_interval] || 99) -
          (INTERVAL_ORDER[b.recurring_interval] || 99)
        );
      });
      const selectedInterval =
        this.selectedIntervals[key] || sortedProducts[0]?.recurring_interval;
      const selectedProduct =
        sortedProducts.find(
          (product) => product.recurring_interval === selectedInterval
        ) ||
        sortedProducts[0];
      const selectedPlan = this.buildPlan(
        selectedProduct,
        this.monthlyPriceFor(sortedProducts, selectedProduct)
      );

      return {
        key,
        name: selectedProduct?.name,
        description: selectedProduct?.description,
        selectedPlan,
        hasMultiplePlans: sortedProducts.length > 1,
        plans: sortedProducts.map((product) => {
          const plan = this.buildPlan(
            product,
            this.monthlyPriceFor(sortedProducts, product)
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
        product.currency === selectedProduct?.currency
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
        (1 - monthlyEquivalentCents / monthlyPrice) * 100
      );
      if (percent > 0) {
        savingsLabel = i18n(
          "discourse_dodo_subscriptions.subscribe.save_percent",
          { percent }
        );
      }
    }

    return {
      product,
      id: product?.id,
      interval: product?.recurring_interval,
      intervalLabel: i18n(
        `discourse_dodo_subscriptions.intervals.${
          product?.recurring_interval || "month"
        }`
      ),
      amountLabel: product?.amountLabel,
      monthlyEquivalentLabel: monthlyEquivalentCents
        ? i18n("discourse_dodo_subscriptions.subscribe.monthly_equivalent", {
            amount: product.formatAmount(monthlyEquivalentCents),
          })
        : null,
      savingsLabel,
      subscribed: product?.subscribed,
      loading: this.loadingProductId === product?.id,
    };
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
        i18n("discourse_dodo_subscriptions.subscribe.login_required")
      );
      return;
    }

    this.loadingProductId = product.id;

    product
      .checkout()
      .then((result) => {
        if (result.subscribed) {
          this.router.transitionTo("dodo-subscribe.success");
        } else if (result.checkout_url) {
          window.location.href = result.checkout_url;
        } else {
          this.dialog.alert(
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error")
          );
          this.loadingProductId = null;
        }
      })
      .catch((error) => {
        this.dialog.alert(
          error?.jqXHR?.responseJSON?.errors?.[0] ||
            i18n("discourse_dodo_subscriptions.subscribe.checkout_error")
        );
        this.loadingProductId = null;
      });
  }
}
