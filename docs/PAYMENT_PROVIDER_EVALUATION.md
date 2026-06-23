# Payment Provider Evaluation (Marketplace Model)

## Scope

This scorecard compares **Razorpay Route** and **Cashfree** for CanCan's selected model:

- CanCan collects customer payments (online/cash).
- CanCan keeps commission.
- CanCan settles vendor net payable via automated payouts.

## Cost Model (What to compare)

For each provider, compute:

`effective_cost = collection_fee + GST + payout_fee + refund_handling_fee + failed_transfer_overheads`

For planning baseline, domestic collection is often around `~2%` plus GST on gateway fees (final negotiated rates to be confirmed with provider sales).

## Scorecard

| Criteria | Razorpay Route | Cashfree | Weight |
|---|---|---|---|
| Split settlement maturity | Strong linked-account route model | Strong split + disbursal model | 20% |
| Payout/disbursal APIs | Good (RazorpayX ecosystem) | Excellent for disbursals | 20% |
| Webhook docs + idempotency support | Strong | Strong | 15% |
| Reconciliation exports | Strong dashboard + APIs | Strong dashboard + APIs | 15% |
| Compliance support for marketplace flows | Strong | Strong | 15% |
| Integration complexity in existing stack | Moderate | Moderate | 15% |

## Preliminary Recommendation

Choose **Razorpay Route** as the default implementation target for phase 1/2 because:

1. Route model aligns directly with one-to-many seller settlement.
2. Mature linked account concepts map cleanly to `vendors`.
3. Existing team familiarity in Indian startup ecosystem is typically higher.

Keep **Cashfree** as a fallback provider via an adapter pattern in code (`provider` column + webhook verification per provider).

## Contract/Onboarding Checklist

- Confirm final negotiated collection fee slabs by monthly GMV tiers.
- Confirm payout transfer fee, failure fee, and reversal/refund charges.
- Confirm settlement windows (T+N), hold/release controls, and holiday behavior.
- Confirm compliance prerequisites for marketplace split flows.
- Confirm webhook retry policy, event ordering guarantees, and signature docs.

## Implementation Decision

- `payment_provider_default = razorpay`
- `payment_provider_fallback = cashfree`
- `settlement_mode = automated_payouts`
