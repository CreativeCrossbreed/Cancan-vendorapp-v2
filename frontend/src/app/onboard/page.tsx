'use client';

import { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import s from './onboard.module.css';

interface FormData {
    name: string;
    address: string;
    flatNumber: string;
    floor: string;
    buildingName: string;
    landmark: string;
    city: string;
    state: string;
    pincode: string;
    latitude: number | null;
    longitude: number | null;
}

export default function OnboardPage() {
    const searchParams = useSearchParams();
    const vendorId = searchParams.get('v');
    const phone = searchParams.get('p');

    const [vendorName, setVendorName] = useState<string>('');
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState('');
    const [locating, setLocating] = useState(false);
    const [locationSet, setLocationSet] = useState(false);

    const [form, setForm] = useState<FormData>({
        name: '',
        address: '',
        flatNumber: '',
        floor: '',
        buildingName: '',
        landmark: '',
        city: '',
        state: '',
        pincode: '',
        latitude: null,
        longitude: null,
    });

    // Validate vendor on mount
    useEffect(() => {
        if (!vendorId || !phone) {
            setLoading(false);
            return;
        }

        fetch(`/api/vendors/public/${vendorId}`)
            .then(res => res.json())
            .then(data => {
                if (data.vendor?.business_name) {
                    setVendorName(data.vendor.business_name);
                }
            })
            .catch(() => { /* vendor name is optional UI sugar */ })
            .finally(() => setLoading(false));
    }, [vendorId, phone]);

    // Reverse geocode helper
    const reverseGeocode = useCallback(async (lat: number, lng: number) => {
        try {
            const res = await fetch(
                `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`,
                { headers: { 'Accept-Language': 'en' } }
            );
            const data = await res.json();
            if (data.address) {
                const addr = data.address;
                setForm(prev => ({
                    ...prev,
                    address: data.display_name || prev.address,
                    city: addr.city || addr.town || addr.village || addr.county || '',
                    state: addr.state || '',
                    pincode: addr.postcode || '',
                }));
            }
        } catch {
            // Silently fail — user can still type address manually
        }
    }, []);

    // Get location from browser
    const handleGetLocation = () => {
        if (!navigator.geolocation) {
            setError('Geolocation is not supported by your browser');
            return;
        }

        setLocating(true);
        setError('');

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const { latitude, longitude } = position.coords;
                setForm(prev => ({ ...prev, latitude, longitude }));
                setLocationSet(true);
                setLocating(false);
                reverseGeocode(latitude, longitude);
            },
            (err) => {
                setLocating(false);
                switch (err.code) {
                    case err.PERMISSION_DENIED:
                        setError('Location access denied. Please allow location access and try again, or type your address manually.');
                        break;
                    case err.POSITION_UNAVAILABLE:
                        setError('Location unavailable. Please type your address manually.');
                        break;
                    default:
                        setError('Could not get your location. Please type your address manually.');
                }
            },
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
        );
    };

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        setForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (!form.name.trim()) {
            setError('Please enter your name');
            return;
        }
        if (!form.address.trim()) {
            setError('Please enter your address');
            return;
        }

        setSubmitting(true);

        try {
            const res = await fetch('/api/customers/onboard', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    phone,
                    vendorId,
                    ...form,
                }),
            });

            const data = await res.json();

            if (!res.ok) {
                setError(data.error || 'Something went wrong. Please try again.');
                return;
            }

            setSuccess(true);
        } catch {
            setError('Network error. Please check your connection and try again.');
        } finally {
            setSubmitting(false);
        }
    };

    // ── Loading State ──
    if (loading) {
        return (
            <div className={s.loadingContainer}>
                <div className={s.spinner} style={{ width: 32, height: 32, borderWidth: 3 }} />
            </div>
        );
    }

    // ── Invalid Link ──
    if (!vendorId || !phone) {
        return (
            <div className={s.successContainer}>
                <div className={s.invalidCard}>
                    <div className={s.invalidIcon}>🔗</div>
                    <h2>Invalid Link</h2>
                    <p>
                        This onboarding link is missing some information.
                        Please scan the QR code on your vendor&apos;s water can to get started.
                    </p>
                </div>
            </div>
        );
    }

    // ── Success Screen ──
    if (success) {
        const whatsappNumber = process.env.NEXT_PUBLIC_WHATSAPP_NUMBER || '';
        return (
            <div className={s.successContainer}>
                <div className={s.successCard}>
                    <div className={s.successIcon}>🎉</div>
                    <h2>You&apos;re all set!</h2>
                    <p>
                        Your profile has been created{vendorName ? ` with ${vendorName}` : ''}.
                        You can now order water cans directly on WhatsApp!
                    </p>
                    <a
                        href={`https://wa.me/${whatsappNumber}?text=order`}
                        className={s.whatsappBtn}
                    >
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" />
                        </svg>
                        Start Ordering on WhatsApp
                    </a>
                </div>
            </div>
        );
    }

    // ── Onboarding Form ──
    return (
        <div className={s.container}>
            <div className={s.card}>
                <div className={s.header}>
                    <div className={s.logo}>🚰</div>
                    <h1>Welcome to Can Can!</h1>
                    {vendorName && (
                        <div className={s.vendorBadge}>
                            📍 Ordering from {vendorName}
                        </div>
                    )}
                </div>

                <form className={s.form} onSubmit={handleSubmit}>
                    {/* Name */}
                    <div className={s.fieldGroup}>
                        <label>Your Name <span className={s.required}>*</span></label>
                        <input
                            id="input-name"
                            className={s.input}
                            type="text"
                            name="name"
                            placeholder="Enter your full name"
                            value={form.name}
                            onChange={handleChange}
                            required
                            autoFocus
                        />
                    </div>

                    {/* Location */}
                    <div className={s.locationSection}>
                        {!locationSet ? (
                            <>
                                <button
                                    id="btn-get-location"
                                    type="button"
                                    className={s.locationBtn}
                                    onClick={handleGetLocation}
                                    disabled={locating}
                                >
                                    {locating ? (
                                        <>
                                            <div className={s.spinner} />
                                            Getting location...
                                        </>
                                    ) : (
                                        <>📍 Share My Location</>
                                    )}
                                </button>
                                <p className={s.locationHint}>
                                    This helps us find vendors near you and ensures accurate delivery
                                </p>
                            </>
                        ) : (
                            <div className={s.locationConfirmed}>
                                ✅ Location captured successfully!
                            </div>
                        )}
                    </div>

                    {/* Address */}
                    <div className={s.fieldGroup}>
                        <label>Delivery Address <span className={s.required}>*</span></label>
                        <textarea
                            id="input-address"
                            className={`${s.input} ${s.textarea}`}
                            name="address"
                            placeholder="Full street address"
                            value={form.address}
                            onChange={handleChange}
                            required
                        />
                    </div>

                    {/* Flat / Floor / Building */}
                    <div className={s.row3}>
                        <div className={s.fieldGroup}>
                            <label>Flat No.</label>
                            <input
                                id="input-flat"
                                className={s.input}
                                type="text"
                                name="flatNumber"
                                placeholder="e.g. 4B"
                                value={form.flatNumber}
                                onChange={handleChange}
                            />
                        </div>
                        <div className={s.fieldGroup}>
                            <label>Floor</label>
                            <input
                                id="input-floor"
                                className={s.input}
                                type="text"
                                name="floor"
                                placeholder="e.g. 3"
                                value={form.floor}
                                onChange={handleChange}
                            />
                        </div>
                        <div className={s.fieldGroup}>
                            <label>Building</label>
                            <input
                                id="input-building"
                                className={s.input}
                                type="text"
                                name="buildingName"
                                placeholder="Name"
                                value={form.buildingName}
                                onChange={handleChange}
                            />
                        </div>
                    </div>

                    {/* Landmark */}
                    <div className={s.fieldGroup}>
                        <label>Landmark</label>
                        <input
                            id="input-landmark"
                            className={s.input}
                            type="text"
                            name="landmark"
                            placeholder="Near temple, park, etc."
                            value={form.landmark}
                            onChange={handleChange}
                        />
                    </div>

                    {/* City / Pincode */}
                    <div className={s.row}>
                        <div className={s.fieldGroup}>
                            <label>City</label>
                            <input
                                id="input-city"
                                className={s.input}
                                type="text"
                                name="city"
                                placeholder="City"
                                value={form.city}
                                onChange={handleChange}
                            />
                        </div>
                        <div className={s.fieldGroup}>
                            <label>Pincode</label>
                            <input
                                id="input-pincode"
                                className={s.input}
                                type="text"
                                name="pincode"
                                placeholder="6 digits"
                                value={form.pincode}
                                onChange={handleChange}
                                maxLength={6}
                                pattern="[0-9]{6}"
                            />
                        </div>
                    </div>

                    {/* Error */}
                    {error && (
                        <div className={s.error}>
                            ⚠️ {error}
                        </div>
                    )}

                    {/* Submit */}
                    <button
                        id="btn-submit"
                        type="submit"
                        className={s.submitBtn}
                        disabled={submitting}
                    >
                        {submitting ? (
                            <>
                                <div className={s.spinner} />
                                Setting up your account...
                            </>
                        ) : (
                            <>Complete Setup →</>
                        )}
                    </button>
                </form>
            </div>
        </div>
    );
}
