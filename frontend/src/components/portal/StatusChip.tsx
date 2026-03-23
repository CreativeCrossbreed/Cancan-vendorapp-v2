'use client';

type StatusVariant = 'success' | 'warning' | 'error' | 'info' | 'neutral';

const variantClasses: Record<StatusVariant, string> = {
    success: 'bg-green-100 text-green-800',
    warning: 'bg-amber-100 text-amber-800',
    error: 'bg-red-100 text-red-800',
    info: 'bg-blue-100 text-blue-800',
    neutral: 'bg-slate-100 text-slate-700',
};

interface StatusChipProps {
    label: string;
    variant?: StatusVariant;
    className?: string;
}

export default function StatusChip({ label, variant = 'neutral', className = '' }: StatusChipProps) {
    return (
        <span
            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${variantClasses[variant]} ${className}`}
        >
            {label}
        </span>
    );
}

/** Maps common status strings to StatusChip variant */
export function statusToVariant(status: string | undefined | null): StatusVariant {
    const s = status?.toLowerCase() ?? '';
    if (['active', 'paid', 'completed', 'delivered', 'success', 'sent'].includes(s)) return 'success';
    if (['pending', 'processing', 'inactive', 'unpaid'].includes(s)) return 'warning';
    if (['cancelled', 'suspended', 'failed', 'error'].includes(s)) return 'error';
    if (['draft', 'info', 'refunded', 'confirmed', 'assigned', 'picked_up'].includes(s)) return 'info';
    return 'neutral';
}
