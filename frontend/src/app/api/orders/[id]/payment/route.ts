import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import {
    appendVendorWalletEntry,
    createPaymentRecord,
    updateOrderFinancialState,
} from '@/lib/finance-ledger';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;
    const {
        payment_status,
        amount,
        collection_mode = 'cash_platform',
        payment_method = 'cash',
        notes,
    } = await req.json();

    if (!payment_status) {
        return Response.json({ error: 'Payment status is required' }, { status: 400 });
    }

    const { data: existingOrder, error: fetchError } = await supabaseAdmin
        .from('orders')
        .select('id, vendor_id, customer_id, total_amount, gross_amount, platform_commission_amount, vendor_net_amount, amount_paid')
        .eq('id', id)
        .single();

    if (fetchError || !existingOrder) {
        return Response.json({ error: fetchError?.message || 'Order not found' }, { status: 404 });
    }

    const grossAmount = Number(existingOrder.gross_amount || existingOrder.total_amount || 0);
    const amountToRecord = Number(amount || grossAmount);
    const commission = Number(existingOrder.platform_commission_amount || 0);
    const vendorNet = Number(existingOrder.vendor_net_amount || Math.max(grossAmount - commission, 0));
    const alreadyPaid = Number(existingOrder.amount_paid || 0);
    const newAmountPaid = Number((alreadyPaid + amountToRecord).toFixed(2));
    const remaining = Number(Math.max(grossAmount - newAmountPaid, 0).toFixed(2));

    if (amountToRecord > 0 && payment_status !== 'unpaid') {
        const payment = await createPaymentRecord({
            orderId: existingOrder.id,
            vendorId: existingOrder.vendor_id,
            customerId: existingOrder.customer_id,
            provider: collection_mode === 'online' ? 'online' : 'cash',
            providerPaymentId: `${collection_mode}_${existingOrder.id}_${Date.now()}`,
            collectionMode:
                collection_mode === 'cash_vendor' ? 'cash_vendor' : collection_mode === 'online' ? 'online' : 'cash_platform',
            amount: amountToRecord,
            paymentMethod: payment_method,
            platformCommission: commission,
            vendorPayable: Number(((vendorNet / Math.max(grossAmount, 1)) * amountToRecord).toFixed(2)),
            status: payment_status === 'failed' ? 'failed' : 'completed',
            idempotencyKey: `manual:${existingOrder.id}:${collection_mode}:${payment_status}:${amountToRecord.toFixed(2)}`,
            metadata: {
                updated_by: admin.email,
                notes: notes || null,
            },
        });

        if (existingOrder.vendor_id && collection_mode !== 'cash_vendor' && payment_status !== 'failed') {
            const paymentId = (payment.id as string | null | undefined) ?? null;
            const { data: existingLedgerEntry } = paymentId
                ? await supabaseAdmin
                      .from('vendor_wallet_ledger')
                      .select('id')
                      .eq('payment_id', paymentId)
                      .eq('vendor_id', existingOrder.vendor_id)
                      .maybeSingle()
                : { data: null };

            if (!existingLedgerEntry) {
                await appendVendorWalletEntry({
                    vendorId: existingOrder.vendor_id,
                    orderId: existingOrder.id,
                    paymentId,
                    entryType: 'credit',
                    sourceType: collection_mode === 'online' ? 'online_payment' : 'cash_collection',
                    amount: Number(((vendorNet / Math.max(grossAmount, 1)) * amountToRecord).toFixed(2)),
                    status: 'posted',
                    notes: `Payment recorded via admin dashboard`,
                });
            }
        }
    }

    const order = await updateOrderFinancialState(existingOrder.id, {
        payment_status:
            payment_status === 'failed'
                ? 'unpaid'
                : remaining <= 0
                  ? 'paid'
                  : 'unpaid',
        payment_state:
            payment_status === 'failed'
                ? 'failed'
                : remaining <= 0
                  ? collection_mode === 'online'
                      ? 'collected_online'
                      : collection_mode === 'cash_vendor'
                        ? 'collected_cash_vendor'
                      : 'collected_cash_platform'
                  : 'partially_collected',
        payment_method,
        amount_paid: newAmountPaid,
        remaining_amount: remaining,
        payment_marked_at: new Date().toISOString(),
    });

    return Response.json(order);
}
