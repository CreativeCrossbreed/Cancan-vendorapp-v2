import crypto from 'node:crypto';

export type SupportedProvider = 'razorpay' | 'cashfree';

type CreateOrderParams = {
  provider: SupportedProvider;
  amountInPaise: number;
  receipt: string;
  notes?: Record<string, string>;
};

function toBase64(input: string) {
  return Buffer.from(input).toString('base64');
}

export async function createProviderOrder(params: CreateOrderParams): Promise<{
  providerOrderId: string;
  checkoutUrl?: string;
  rawResponse?: unknown;
}> {
  if (params.provider === 'razorpay') {
    const keyId = process.env.RAZORPAY_KEY_ID || '';
    const keySecret = process.env.RAZORPAY_KEY_SECRET || '';

    if (!keyId || !keySecret) {
      return {
        providerOrderId: `mock_rzp_${params.receipt}`,
        checkoutUrl: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/mock-payment?provider=razorpay&receipt=${encodeURIComponent(params.receipt)}`,
      };
    }

    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      signal: AbortSignal.timeout(8000),
      headers: {
        Authorization: `Basic ${toBase64(`${keyId}:${keySecret}`)}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        amount: params.amountInPaise,
        currency: 'INR',
        receipt: params.receipt,
        notes: params.notes || {},
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Razorpay order create failed (${response.status}): ${body}`);
    }

    const data = await response.json();
    return {
      providerOrderId: data.id,
      rawResponse: data,
    };
  }

  const appId = process.env.CASHFREE_APP_ID || '';
  const secretKey = process.env.CASHFREE_SECRET_KEY || '';
  const baseUrl = process.env.CASHFREE_BASE_URL || 'https://api.cashfree.com/pg';

  if (!appId || !secretKey) {
    return {
      providerOrderId: `mock_cf_${params.receipt}`,
      checkoutUrl: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/mock-payment?provider=cashfree&receipt=${encodeURIComponent(params.receipt)}`,
    };
  }

  const response = await fetch(`${baseUrl}/orders`, {
    method: 'POST',
    signal: AbortSignal.timeout(8000),
    headers: {
      'x-api-version': '2023-08-01',
      'x-client-id': appId,
      'x-client-secret': secretKey,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      order_id: params.receipt,
      order_amount: Number((params.amountInPaise / 100).toFixed(2)),
      order_currency: 'INR',
      order_note: 'CanCan marketplace payment',
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Cashfree order create failed (${response.status}): ${body}`);
  }

  const data = await response.json();
  return {
    providerOrderId: data.order_id || params.receipt,
    checkoutUrl: data.payment_link,
    rawResponse: data,
  };
}

export function verifyWebhookSignature(
  provider: SupportedProvider,
  rawBody: string,
  headers: Headers,
): boolean {
  if (provider === 'razorpay') {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) return process.env.NODE_ENV !== 'production';

    const signature = headers.get('x-razorpay-signature');
    if (!signature) return false;

    const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    return signature === expected;
  }

  const secret = process.env.CASHFREE_WEBHOOK_SECRET;
  if (!secret) return process.env.NODE_ENV !== 'production';

  const signature =
    headers.get('x-webhook-signature') ||
    headers.get('x-cashfree-signature') ||
    headers.get('x-signature');
  if (!signature) return false;

  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('base64');
  return signature === expected;
}

export function detectProviderFromHeaders(headers: Headers): SupportedProvider {
  if (headers.get('x-razorpay-signature')) return 'razorpay';
  return 'cashfree';
}
