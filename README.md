# Discourse Dodo Payments Subscriptions

Sell Dodo Payments subscriptions that grant access to Discourse groups.

## Routes

- Public subscription page: `/subscribe`
- User subscription status page: `/u/:username/billing/subscriptions`
- Dodo webhook endpoint: `/subscribe/webhooks/dodo`
- Admin product configuration: `/admin/plugins/discourse-dodo-subscriptions/products`

## Settings

- `discourse_dodo_subscriptions_enabled`
- `discourse_dodo_subscriptions_api_key`
- `discourse_dodo_subscriptions_webhook_secret`
- `discourse_dodo_subscriptions_environment`, either `test` or `live`
- `discourse_dodo_subscriptions_base_url`, usually leave blank. The plugin automatically uses the Dodo Payments test or live API URL based on the selected environment.

## Product configuration

Create one row per Dodo Payments product at:

`/admin/plugins/discourse-dodo-subscriptions/products`

The `Dodo product ID` field is the product id from Dodo Payments. The `Discourse group name` field is the local Discourse group granted when a matching subscription webhook is received.

Do not put a product id in `discourse_dodo_subscriptions_base_url`; that setting is only for overriding the Dodo Payments API host.

The amount, currency, and billing interval fields are display fields for the Discourse subscription page. Dodo Payments still controls the real checkout price and billing cycle for each product ID.

To offer monthly, quarterly, half-yearly, and yearly options, create one Dodo product for each option, then add one row per product ID in Discourse with the same display name. The subscription page groups rows with the same display name into one pricing card and shows interval choices. If the longer interval is cheaper than the monthly equivalent, the page shows the calculated discount automatically.

After checkout, Dodo Payments webhooks update the local subscription record and group access. Users can view their recorded Dodo subscription status at `/u/:username/billing/subscriptions`.

## Dodo webhook URL

Configure this endpoint in Dodo Payments:

`https://your-discourse-host/subscribe/webhooks/dodo`

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
