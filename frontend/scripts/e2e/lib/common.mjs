import fs from 'node:fs';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';

const ROOT_DIR = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', '..', '..');
const MANIFEST_DIR = path.join(ROOT_DIR, 'scripts', 'e2e', 'manifests');

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const contents = fs.readFileSync(filePath, 'utf8');
  for (const line of contents.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIndex = trimmed.indexOf('=');
    if (eqIndex <= 0) continue;
    const key = trimmed.slice(0, eqIndex).trim();
    let value = trimmed.slice(eqIndex + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

function loadFrontendEnvFiles() {
  loadEnvFile(path.join(ROOT_DIR, '.env'));
  loadEnvFile(path.join(ROOT_DIR, '.env.local'));
}

function coerceValue(value) {
  if (value === 'true') return true;
  if (value === 'false') return false;
  if (value === 'null') return null;
  if (value !== '' && !Number.isNaN(Number(value))) return Number(value);
  return value;
}

export function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      args._.push(token);
      continue;
    }

    const [rawKey, rawInlineValue] = token.slice(2).split('=');
    const key = rawKey.trim();
    if (!key) continue;

    if (rawInlineValue !== undefined) {
      args[key] = coerceValue(rawInlineValue);
      continue;
    }

    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }

    args[key] = coerceValue(next);
    i += 1;
  }
  return args;
}

export function requireArg(args, key) {
  const value = args[key];
  if (value === undefined || value === null || value === '') {
    throw new Error(`Missing required argument: --${key}`);
  }
  return String(value);
}

export function nowIso() {
  return new Date().toISOString();
}

export function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

export function getManifestPath(runId) {
  ensureDir(MANIFEST_DIR);
  return path.join(MANIFEST_DIR, `${runId}.json`);
}

export function readManifest(runId) {
  const manifestPath = getManifestPath(runId);
  if (!fs.existsSync(manifestPath)) {
    throw new Error(`Manifest not found for runId "${runId}" at ${manifestPath}`);
  }
  return JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}

export function writeManifest(manifest) {
  if (!manifest?.runId) {
    throw new Error('Manifest must include runId');
  }
  const manifestPath = getManifestPath(manifest.runId);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  return manifestPath;
}

export function createSupabaseAdminClient() {
  loadFrontendEnvFiles();
  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl) {
    throw new Error('Missing SUPABASE_URL or NEXT_PUBLIC_SUPABASE_URL');
  }
  if (!serviceRoleKey) {
    throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY');
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export async function getTableColumns(supabase, table) {
  const knownColumns = {
    products: ['id', 'name', 'price', 'description', 'category', 'is_active', 'created_at', 'updated_at'],
    customers: [
      'id',
      'phone',
      'name',
      'address',
      'flat_number',
      'floor',
      'building_name',
      'landmark',
      'latitude',
      'longitude',
      'city',
      'state',
      'pincode',
      'created_at',
      'updated_at',
    ],
    orders: [
      'id',
      'order_number',
      'vendor_id',
      'customer_id',
      'delivery_date',
      'time_slot',
      'delivery_time_slot',
      'total_amount',
      'subtotal',
      'status',
      'is_delivered',
      'delivered_at',
      'payment_status',
      'amount_paid',
      'remaining_amount',
      'notes',
      'source',
      'order_items',
      'delivery_address',
      'created_at',
      'updated_at',
    ],
    order_items: ['id', 'order_id', 'product_id', 'quantity', 'unit_price', 'subtotal', 'created_at'],
    vendor_products: [
      'id',
      'vendor_id',
      'product_id',
      'selling_price',
      'deposit_amount',
      'current_stock',
      'low_stock_threshold',
      'is_active',
      'created_at',
      'updated_at',
    ],
    whatsapp_sessions: [
      'id',
      'phone_number',
      'state',
      'name',
      'latitude',
      'longitude',
      'address',
      'pending_address',
      'customer_id',
      'vendor_id',
      'can_count',
      'delivery_date',
      'time_slot',
      'created_at',
      'updated_at',
    ],
    whatsapp_messages: [
      'id',
      'message_id',
      'customer_phone',
      'message_type',
      'message_content',
      'direction',
      'status',
      'created_at',
    ],
    customer_vendors: ['customer_id', 'vendor_id', 'referral_source', 'created_at'],
  };

  const fallback = new Set(knownColumns[table] || []);
  if (!supabase) return fallback;

  // Avoid querying information_schema via PostgREST (not exposed by default).
  // Best effort: infer existing columns from one row if table has data.
  const { data } = await supabase.from(table).select('*').limit(1);
  if (Array.isArray(data) && data.length > 0) {
    return new Set([...fallback, ...Object.keys(data[0])]);
  }

  return fallback;
}

export function makePhoneForRun(runId, index = 0) {
  const seed = `${runId}-${index}`;
  let hash = 0;
  for (let i = 0; i < seed.length; i += 1) {
    hash = (hash * 31 + seed.charCodeAt(i)) % 1_000_000_000;
  }
  const suffix = String(hash).padStart(9, '0').slice(0, 9);
  return `91${suffix}`;
}

export function makeMessageId(runId, phone, stepIndex) {
  const normalized = phone.replace(/\D/g, '');
  return `e2e_${runId}_${normalized}_${String(stepIndex).padStart(3, '0')}`;
}

export function logJson(title, data) {
  console.log(`\n${title}`);
  console.log(JSON.stringify(data, null, 2));
}
