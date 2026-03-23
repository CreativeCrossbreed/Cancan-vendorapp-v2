'use client';

interface PortalPageHeaderProps {
    title: string;
    subtitle?: string;
}

export default function PortalPageHeader({ title, subtitle }: PortalPageHeaderProps) {
    return (
        <div className="mb-6">
            <h1 className="text-2xl font-semibold text-slate-900 mb-1">
                {title}
            </h1>
            {subtitle && (
                <p className="text-slate-600">{subtitle}</p>
            )}
        </div>
    );
}
