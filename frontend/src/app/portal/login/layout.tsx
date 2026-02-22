'use client';

import { StoreProvider } from '@/store/StoreProvider';

export default function LoginLayout({ children }: { children: React.ReactNode }) {
    return <StoreProvider>{children}</StoreProvider>;
}
