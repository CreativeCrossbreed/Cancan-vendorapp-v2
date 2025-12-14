# Can Can Vendor App

A Flutter mobile application for water can delivery vendors to manage their business operations including order management, inventory tracking, and payment processing.

## Features

- 🔐 **Phone-based Authentication** - Secure OTP verification via Supabase
- 📱 **Real-time Order Management** - View and update order statuses
- 📊 **Dashboard Analytics** - Daily earnings and delivery summaries
- 📦 **Inventory Tracking** - Monitor stock levels and product availability
- 💰 **Payment Tracking** - Track paid and unpaid orders
- 🏖️ **Vacation Mode** - Temporarily pause order acceptance
- 📄 **QR Code Generation** - Easy customer ordering via QR codes
- 🔄 **Real-time Updates** - Order status changes via Supabase Realtime

## Technology Stack

- **Framework**: Flutter 3.0+
- **Backend**: Supabase (PostgreSQL + Authentication + Realtime)
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences

## Prerequisites

Before running the app, ensure you have:

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- A Supabase project (free tier is sufficient)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd vendor_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Get your Supabase credentials:
   - Go to [supabase.com](https://supabase.com)
   - Create a new project or use existing one
   - Navigate to Settings → API
   - Copy the Project URL and anon key

3. Edit `.env` file with your credentials:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anonymous_key
   ```

### 4. Database Setup

Run the following SQL in your Supabase SQL Editor to create the required tables:

```sql
-- Vendors table
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  business_name VARCHAR(255),
  address TEXT,
  is_on_vacation BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Vendor products (junction table)
CREATE TABLE vendor_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  selling_price DECIMAL(10,2) NOT NULL,
  current_stock INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT true,
  UNIQUE(vendor_id, product_id)
);

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  address TEXT NOT NULL,
  flat_number VARCHAR(50),
  floor VARCHAR(10),
  building_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Orders table
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  delivery_date DATE NOT NULL,
  time_slot VARCHAR(50) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, completed, cancelled
  is_delivered BOOLEAN DEFAULT false,
  delivered_at TIMESTAMP WITH TIME ZONE,
  payment_status VARCHAR(20) DEFAULT 'unpaid', -- paid, unpaid
  payment_marked_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Order items table
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Insert sample products
INSERT INTO products (name, description) VALUES
('20L Water Can', 'Standard 20 liter water can'),
('10L Water Can', 'Compact 10 liter water can'),
('5L Water Can', 'Small 5 liter water can');
```

### 5. Running the App

```bash
# Run in debug mode
flutter run

# Build for production (Android)
flutter build apk --release

# Build for production (iOS)
flutter build ios --release
```

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Generate app icons (after updating icons)
flutter pub run flutter_launcher_icons:main
```

## Project Structure

```
lib/
├── config/          # Configuration files (theme, constants)
├── models/          # Data models (Order, Customer, etc.)
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── home/        # Dashboard and main screens
│   ├── catalog/     # Product catalog
│   ├── history/     # Order history
│   ├── payments/    # Payment management
│   ├── inventory/   # Inventory tracking
│   ├── settings/    # App settings
│   └── qr_code/     # QR code generation
├── services/        # Business logic and API services
└── utils/           # Utility functions (logger, error handler)
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Code Quality

- Follow Flutter's official style guide
- Use `flutter analyze` to check for issues
- Write tests for new features
- Use the logger instead of print statements

## Support

For support and questions:
- Email: support@cancan.app
- Create an issue in this repository

## License

This project is proprietary and confidential. © 2025 Can Can Vendor App.