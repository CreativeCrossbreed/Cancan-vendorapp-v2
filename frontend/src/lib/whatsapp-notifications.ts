import { sendReplyButtons, sendWhatsAppMessage } from '@/lib/whatsapp';

export async function notifyOrderAccepted(customerPhone: string, orderId: string, vendorName: string) {
  await sendWhatsAppMessage(
    customerPhone,
    `✅ *Order Confirmed!*\n\nYour order *${orderId}* has been accepted by *${vendorName}*.\n\nWe'll notify you when it's delivered. 💧`,
  );
}

export async function notifyOrderDelivered(customerPhone: string, orderId: string, vendorName: string) {
  await sendWhatsAppMessage(
    customerPhone,
    `💧 *Your order has been delivered!*\n\nOrder *${orderId}* from *${vendorName}* is complete. Thank you!\n\n_Send "Hi" to begin your next order._`,
  );
}

export async function notifyDeliveryFailed(customerPhone: string, deliveryDate: string) {
  await sendReplyButtons(
    customerPhone,
    `⚠️ *Delivery Attempt Failed*\n\nWe're sorry — your delivery for *${deliveryDate}* could not be completed.\n\nYour order will be delivered tomorrow.`,
    [
      { id: 'failed_okay', title: '👍 Okay' },
      { id: 'failed_contact_vendor', title: '📞 Contact Vendor' },
    ],
  );
}
