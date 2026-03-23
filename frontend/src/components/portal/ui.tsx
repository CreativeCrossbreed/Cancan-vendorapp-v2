'use client';

import React, { useEffect } from 'react';

export function Card({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-xl border border-slate-200 bg-white shadow-sm ${className}`}>
      {children}
    </div>
  );
}

export function Button({
  children,
  className = '',
  variant = 'primary',
  size = 'md',
  type = 'button',
  disabled,
  onClick,
}: {
  children: React.ReactNode;
  className?: string;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  type?: 'button' | 'submit' | 'reset';
  disabled?: boolean;
  onClick?: () => void;
}) {
  const base =
    'inline-flex items-center justify-center rounded-xl font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cancan-primary/40 disabled:opacity-60 disabled:cursor-not-allowed';
  const sizes: Record<typeof size, string> = {
    sm: 'h-9 px-3 text-sm',
    md: 'h-10 px-4 text-sm',
    lg: 'h-11 px-5 text-base',
  };
  const variants: Record<typeof variant, string> = {
    primary: 'bg-cancan-primary text-white hover:bg-cancan-primary-dark shadow-sm shadow-cancan-primary/25',
    secondary: 'bg-slate-900 text-white hover:bg-slate-800',
    danger: 'bg-red-600 text-white hover:bg-red-700',
    ghost: 'bg-transparent text-slate-700 hover:bg-slate-100 border border-slate-200',
  };

  return (
    <button type={type} disabled={disabled} onClick={onClick} className={`${base} ${sizes[size]} ${variants[variant]} ${className}`}>
      {children}
    </button>
  );
}

export function Input({
  label,
  value,
  onChange,
  type = 'text',
  placeholder,
  required,
  className = '',
  right,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  placeholder?: string;
  required?: boolean;
  className?: string;
  right?: React.ReactNode;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="block text-sm font-medium text-slate-700 mb-1">{label}</span>
      <div className="relative">
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          type={type}
          placeholder={placeholder}
          required={required}
          className="w-full h-11 rounded-xl border border-slate-200 bg-white px-4 pr-11 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
        />
        {right ? <div className="absolute inset-y-0 right-0 flex items-center pr-3">{right}</div> : null}
      </div>
    </label>
  );
}

export function Select({
  label,
  value,
  onChange,
  options,
  className = '',
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: Array<{ value: string; label: string }>;
  className?: string;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="block text-sm font-medium text-slate-700 mb-1">{label}</span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full h-11 rounded-xl border border-slate-200 bg-white px-4 text-slate-900 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </label>
  );
}

export function Modal({
  open,
  title,
  onClose,
  children,
  footer,
  maxWidthClassName = 'max-w-xl',
}: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  footer?: React.ReactNode;
  maxWidthClassName?: string;
}) {
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50">
      <button type="button" className="absolute inset-0 bg-black/40" onClick={onClose} aria-label="Close dialog" />
      <div className="relative z-10 min-h-full flex items-center justify-center p-4">
        <div className={`w-full ${maxWidthClassName} rounded-2xl bg-white border border-slate-200 shadow-xl overflow-hidden`}>
          <div className="px-5 py-4 border-b border-slate-100">
            <h2 className="text-base font-semibold text-slate-900">{title}</h2>
          </div>
          <div className="p-5">{children}</div>
          {footer ? <div className="px-5 py-4 border-t border-slate-100 flex items-center justify-end gap-2">{footer}</div> : null}
        </div>
      </div>
    </div>
  );
}

export function Pagination({
  count,
  page,
  rowsPerPage,
  rowsPerPageOptions,
  onPageChange,
  onRowsPerPageChange,
}: {
  count: number;
  page: number; // 0-based
  rowsPerPage: number;
  rowsPerPageOptions: number[];
  onPageChange: (newPage: number) => void;
  onRowsPerPageChange: (newRowsPerPage: number) => void;
}) {
  const totalPages = Math.max(1, Math.ceil(count / rowsPerPage));
  const canPrev = page > 0;
  const canNext = page < totalPages - 1;

  return (
    <div className="flex items-center justify-between gap-3 px-4 py-3 border-t border-slate-100 bg-white">
      <div className="flex items-center gap-2 text-sm text-slate-600">
        <span>Rows</span>
        <select
          value={rowsPerPage}
          onChange={(e) => onRowsPerPageChange(parseInt(e.target.value, 10))}
          className="h-9 rounded-lg border border-slate-200 bg-white px-2 text-slate-900"
        >
          {rowsPerPageOptions.map((n) => (
            <option key={n} value={n}>
              {n}
            </option>
          ))}
        </select>
        <span className="hidden sm:inline">·</span>
        <span className="hidden sm:inline">
          Page {page + 1} of {totalPages}
        </span>
      </div>
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" disabled={!canPrev} onClick={() => onPageChange(page - 1)}>
          Prev
        </Button>
        <Button variant="ghost" size="sm" disabled={!canNext} onClick={() => onPageChange(page + 1)}>
          Next
        </Button>
      </div>
    </div>
  );
}

