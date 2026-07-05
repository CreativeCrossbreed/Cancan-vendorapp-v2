import { NextRequest } from 'next/server';
import { sendOtp, toTenDigits } from '@/lib/two-factor';
import { isRateLimited } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';
export const maxDuration = 30;

export async function POST(req: NextRequest) {
    try {
        const { phone } = await req.json();
        const phone10 = toTenDigits(String(phone ?? ''));
        if (!phone10) {
            return Response.json({ success: false, message: 'Enter a valid 10-digit mobile number.' }, { status: 400 });
        }

        // Throttle: max 5 sends per number per 10 min (SMS credits cost money).
        if (isRateLimited(`otp-send:${phone10}`, 5, 10 * 60 * 1000)) {
            return Response.json(
                { success: false, message: 'Too many OTP requests. Please wait a few minutes.' },
                { status: 429 },
            );
        }

        const result = await sendOtp(phone10);
        if (!result.success) {
            // Surface the real reason instead of pretending success — this was
            // the exact failure mode of the old Twilio path (errors swallowed,
            // UI always said "OTP sent").
            console.error('[send-otp] 2Factor error:', result.details);
            return Response.json(
                { success: false, message: 'Could not send OTP. Please try again.' },
                { status: 502 },
            );
        }

        return Response.json({ success: true, message: 'OTP sent successfully' });
    } catch (e) {
        console.error('[send-otp] error:', e);
        return Response.json({ success: false, message: 'Internal error' }, { status: 500 });
    }
}
