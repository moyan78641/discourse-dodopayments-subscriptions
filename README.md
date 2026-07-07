# Discourse Dodo Payments Subscriptions

Sell Dodo Payments subscriptions that grant access to Discourse groups.

## Routes

- Public subscription page: `/subscribe`
- Dodo webhook endpoint: `/subscribe/webhooks/dodo`
- Admin product configuration: `/admin/plugins/discourse-dodo-subscriptions/products`

## Settings

- `discourse_dodo_subscriptions_enabled`
- `discourse_dodo_subscriptions_api_key`
- `discourse_dodo_subscriptions_webhook_secret`
- `discourse_dodo_subscriptions_environment`, either `test` or `live`

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
