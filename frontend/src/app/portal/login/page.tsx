'use client';

import React, { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { useDispatch, useSelector } from 'react-redux';
import { login, clearError } from '@/store/authSlice';
import type { AppDispatch, RootState } from '@/store';
import { Button, Card, Input } from '@/components/portal/ui';

export default function LoginPage() {
    const router = useRouter();
    const dispatch = useDispatch<AppDispatch>();
    const { isLoading, error } = useSelector((state: RootState) => state.auth);

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);

    const handleSubmit = async (e: FormEvent) => {
        e.preventDefault();
        dispatch(clearError());
        const result = await dispatch(login({ email, password }));
        if (login.fulfilled.match(result)) {
            router.push('/portal/dashboard');
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-cancan-bg via-cancan-soft to-cancan-primary/10 p-4">
            <Card className="p-6 sm:p-10 max-w-[440px] w-full border-slate-200/60 shadow-xl">
                <div className="text-center mb-8">
                    <Image
                        src="/cancan/cancan-logo.png"
                        alt="Can Can"
                        width={140}
                        height={52}
                        priority
                        className="block mx-auto mb-4"
                    />
                    <h1 className="text-xl font-extrabold tracking-tight text-cancan-text">
                        Admin Portal
                    </h1>
                    <p className="mt-1 text-sm text-slate-600">
                        Sign in to manage your platform
                    </p>
                </div>

                {error && (
                    <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <Input
                        label="Email"
                        type="email"
                        value={email}
                        onChange={setEmail}
                        required
                        className="mb-3"
                    />
                    <Input
                        label="Password"
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={setPassword}
                        required
                        className="mb-4"
                        right={
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="text-xs font-semibold text-slate-600 hover:text-slate-900"
                            >
                                {showPassword ? 'Hide' : 'Show'}
                            </button>
                        }
                    />
                    <Button type="submit" size="lg" disabled={isLoading} className="w-full">
                        {isLoading ? 'Signing in…' : 'Sign In'}
                    </Button>
                </form>

                <p className="mt-6 text-center text-xs text-slate-500">
                    Access restricted to authorized administrators only
                </p>
            </Card>
        </div>
    );
}

