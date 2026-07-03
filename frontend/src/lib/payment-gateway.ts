import crypto from 'node:crypto';
import { supabaseAdmin } from './supabase';

export type SupportedProvider = 'razorpay' | 'cashfree';

// Cashfree credentials, sourced from a config row in whatsapp_sessions
// (phone_number '__cf_config__': app_id in `name`, secret_key in `address`,
// base_url in `pending_address`) so they can be set/rotated via the REST API
// without a migration or redeploy. Falls back to environment variables.
let _cfCache: { appId: string; secretKey: string; baseUrl: string; at: number } | null = null;
async function getCashfreeConfig() {
  if (_cfCache && Date.now() - _cfCache.at < 60_000) {
    return { appId: _cfCache.appId, secretKey: _cfCache.secretKey, baseUrl: _cfCache.baseUrl };
  }
  let appId = '';
  let secretKey = '';
  let baseUrl = '';
  try {
    const { data } = await supabaseAdmin
      .from('whatsapp_sessions')
      .select('name, address, pending_address')
      .eq('phone_number', '__cf_config__')
      .maybeSingle();
    if (data) {
      appId = (data as any).name || '';
      secretKey = (data as any).address || '';
      baseUrl = (data as any).pending_address || '';
    }
  } catch {
    // fall through to env
  }
  appId = appId || process.env.CASHFREE_APP_ID || '';
  secretKey = secretKey || process.env.CASHFREE_SECRET_KEY || '';
  baseUrl = baseUrl || process.env.CASHFREE_BASE_URL || 'https://api.cashfree.com/pg';
  if (appId && secretKey) _cfCache = { appId, secretKey, baseUrl, at: Date.now() };
  return { appId, secretKey, baseUrl };
}

type CreateOrderParams = {
  provider: SupportedProvider;
  amountInPaise: number;
  receipt: string;
  notes?: Record<string, string>;
  customerId?: string;
  customerPhone?: string;
  customerEmail?: string;
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
      if (process.env.NODE_ENV === 'production') {
        // A real production deploy with no payment keys configured must not
        // silently hand customers a fake checkout URL — fail loudly so this
        // gets noticed and fixed instead of "working" while collecting no money.
        throw new Error('RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET missing in production — refusing to create a mock payment order.');
      }
      return {
        providerOrderId: `mock_rzp_${params.receipt}`,
        checkoutUrl: `${process.env.NEXT_PUBLIC_APP_URL || 'https://cancanindia.com'}/mock-payment?provider=razorpay&receipt=${encodeURIComponent(params.receipt)}`,
      };
    }

    if (process.env.NODE_ENV === 'production' && keyId.startsWith('rzp_test_')) {
      throw new Error('RAZORPAY_KEY_ID is a test-mode key (rzp_test_*) — refusing to use it in production.');
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

  const { appId, secretKey, baseUrl } = await getCashfreeConfig();

  if (!appId || !secretKey) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('CASHFREE_APP_ID/CASHFREE_SECRET_KEY missing in production — refusing to create a mock payment order.');
    }
    return {
      providerOrderId: `mock_cf_${params.receipt}`,
      checkoutUrl: `${process.env.NEXT_PUBLIC_APP_URL || 'https://cancanindia.com'}/mock-payment?provider=cashfree&receipt=${encodeURIComponent(params.receipt)}`,
    };
  }

  // Sandbox is allowed in production while testing. Credentials sourced from
  // the DB config row are an explicit, intentional test setup — swapping to
  // live keys is a one-row update (change base_url + keys, no redeploy).
  // Guard only against an ACCIDENTAL sandbox base_url when keys look live.

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
      order_note: 'Can Can marketplace payment',
      // Cashfree's Orders API rejects the request without this — customer_id
      // and customer_phone are mandatory, not optional.
      customer_details: {
        customer_id: params.customerId || params.receipt,
        customer_phone: params.customerPhone || '9999999999',
        ...(params.customerEmail ? { customer_email: params.customerEmail } : {}),
      },
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

function timingSafeCompare(a: string, b: string): boolean {
  const aBuf = Buffer.from(a);
  const bBuf = Buffer.from(b);
  if (aBuf.length !== bBuf.length) {
    crypto.timingSafeEqual(aBuf, aBuf);
    return false;
  }
  return crypto.timingSafeEqual(aBuf, bBuf);
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
    return timingSafeCompare(signature, expected);
  }

  const secret = process.env.CASHFREE_WEBHOOK_SECRET;
  if (!secret) return process.env.NODE_ENV !== 'production';

  const signature =
    headers.get('x-webhook-signature') ||
    headers.get('x-cashfree-signature') ||
    headers.get('x-signature');
  if (!signature) return false;

  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('base64');
  return timingSafeCompare(signature, expected);
}

export function detectProviderFromHeaders(headers: Headers): SupportedProvider {
  if (headers.get('x-razorpay-signature')) return 'razorpay';
  return 'cashfree';
}
