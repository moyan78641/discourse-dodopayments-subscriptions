# Discourse Dodo Payments Memberships

Sell recurring subscriptions and one-time memberships through Dodo Payments. Successful payments grant access to configured Discourse groups.

## Routes

- Public membership page: `/subscribe`
- User membership status page: `/u/:username/billing/subscriptions`
- Dodo webhook endpoint: `/subscribe/webhooks/dodo`
- Admin product configuration: `/admin/plugins/discourse-dodo-subscriptions/products`
- Admin orders and manual grants: `/admin/plugins/discourse-dodo-subscriptions/orders`

## Settings

- `discourse_dodo_subscriptions_enabled`
- `discourse_dodo_subscriptions_api_key`
- `discourse_dodo_subscriptions_webhook_secret`
- `discourse_dodo_subscriptions_environment`, either `test` or `live`
- `discourse_dodo_subscriptions_base_url`, usually leave blank. The plugin automatically uses the Dodo Payments test or live API URL based on the selected environment.
- `discourse_dodo_subscriptions_reminder_days`, comma-separated reminder days for one-time memberships, such as `7,3,1`
- `discourse_dodo_subscriptions_notify_on_purchase`
- `discourse_dodo_subscriptions_notify_on_expiration`

## Product configuration

Create one row per Dodo Payments product at:

`/admin/plugins/discourse-dodo-subscriptions/products`

The `Dodo product ID` is the product ID from Dodo Payments. The `Discourse group name` is the local group granted after a matching webhook is verified.

Do not put a product id in `discourse_dodo_subscriptions_base_url`; that setting is only for overriding the Dodo Payments API host.

The amount, currency, and interval fields are display and access-duration fields in Discourse. Dodo Payments still controls the actual checkout price and, for recurring products, the billing cycle associated with the product ID.

Existing products created before the hybrid-membership upgrade remain `subscription` products automatically.

## Recurring and one-time products

Use `subscription` for automatic renewal. Use `one_time` for prepaid access that expires and can be renewed manually.

One-time purchases require a separate one-time product in Dodo Payments. Do not reuse a recurring product ID for a one-time row.

Products with the same `plan_key` are combined into one card on `/subscribe`. This lets one membership plan offer:

- Automatic renewal or one-time purchase
- Monthly, quarterly, half-yearly, and yearly options
- Different prices and automatically calculated longer-term discounts

One-time renewals extend from the later of the current time or the user's existing expiry for the same Discourse group.

## WeChat Pay

Enable WeChat Pay only on `one_time` products. The checkout request then includes:

```json
{
  "allowed_payment_method_types": ["we_chat_pay", "credit", "debit"]
}
```

Dodo Payments currently requires WeChat Pay purchases to be one-time, use `USD` or `CNY`, and meet the minimum amount of `$0.50` or `CNY 1.00`. The plugin validates these constraints before saving a product.

After checkout, Dodo Payments webhooks update the local membership record and group access. Users can view automatic subscriptions and one-time expiry dates at `/u/:username/billing/subscriptions`.

The hourly membership job sends configured expiry reminders, marks ended one-time orders as expired, and removes group access only when no other valid recurring subscription or one-time order remains.

Administrators can use the orders page to search membership records, create manual grants for offline payments, extend access, set an exact expiry, or revoke an order. Manual actions are recorded in the order event log.

## Dodo webhook URL

Configure this endpoint in Dodo Payments:

`https://your-discourse-host/subscribe/webhooks/dodo`

Use the webhook secret for the same test or live environment selected in Discourse. At minimum, enable the subscription lifecycle, `payment.succeeded`, and `refund.succeeded` events used by this plugin.

## Docker Install

Add this to `/var/discourse/containers/app.yml`:

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/moyan78641/discourse-dodopayments-subscriptions.git
```

Then rebuild Discourse:

```bash
cd /var/discourse
./launcher rebuild app
```
