# Project Configuration - Can Can Vendor App

## 📋 Overview
Water can delivery vendor management system with Flutter mobile app and React admin dashboard.

## 🏗️ Architecture

### Dashboard (React Admin Dashboard)
- **Location**: `/dashboard/`
- **Tech Stack**: React 19, TypeScript, Material-UI v7, Redux Toolkit
- **Port**: 3001
- **Build**: `npm run build`
- **Dev**: `npm start`

### Server (Node.js API)
- **Location**: `/server/`
- **Tech Stack**: Express, TypeScript, Supabase, Socket.IO
- **Port**: 5000
- **Build**: `pnpm build`
- **Dev**: `pnpm dev`

### Mobile App (Flutter)
- **Location**: `/android/`
- **Tech Stack**: Flutter, Supabase, Provider pattern
- **Platform**: iOS/Android

## 🔧 Configuration Files

### Environment Variables

#### Server (.env)
```bash
# Supabase Configuration
SUPABASE_URL=https://placeholder.supabase.co
SUPABASE_ANON_KEY=placeholder_anon_key

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=7d

# Server Configuration
PORT=5000
NODE_ENV=development

# CORS Configuration
FRONTEND_URL=http://localhost:3001
```

#### Dashboard (.env)
```bash
# Backend API URL
REACT_APP_API_URL=http://localhost:5000/api

# WebSocket URL (for Socket.IO)
REACT_APP_WS_URL=http://localhost:5000
```

#### Flutter (.env)
```bash
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anonymous_key
```

### Database Schema (Supabase)
Required tables for production:
- `vendors` - Vendor information and profiles
- `products` - Product catalog
- `vendor_products` - Vendor-specific products and pricing
- `customers` - Customer information
- `orders` - Order management
- `order_items` - Order line items
- `admin_users` - Admin user accounts
- `whatsapp_messages` - WhatsApp message logs
- `commission_records` - Commission tracking

## 🚀 Development Commands

### Dashboard
```bash
cd dashboard
npm install
npm start          # Development server
npm run build      # Production build
npm test           # Run tests
```

### Server
```bash
cd server
pnpm install
pnpm dev           # Development server with hot reload
pnpm build         # Build TypeScript
pnpm start         # Production server
```

### Mobile App
```bash
flutter pub get
flutter run        # Run on device/emulator
flutter build apk   # Build Android
flutter build ios   # Build iOS
flutter test        # Run tests
```

## 🔐 Security & Development Mode

### Development Mode Features
- **Backend**: Mock authentication bypass for `admin@cancan.com`/`admin123`
- **Mobile App**: Dev mode with phone `1111111111` for auto-login
- **CORS**: Configured for localhost development

### Production Requirements
- Replace placeholder Supabase credentials
- Remove development mode bypasses
- Set up proper database tables
- Configure production secrets

## 📦 Key Dependencies

### Frontend
- `@mui/material` v7.3.6 - UI Components
- `@reduxjs/toolkit` v2.11.2 - State Management
- `react-router-dom` v7.10.1 - Routing
- `axios` v1.13.2 - HTTP Client
- `recharts` v3.6.0 - Charts

### Backend
- `express` v5.2.1 - Web Framework
- `@supabase/supabase-js` v2.88.0 - Database Client
- `jsonwebtoken` v9.0.3 - JWT Authentication
- `socket.io` v4.8.1 - Real-time Communication
- `typescript` v5.9.3 - Type System

### Mobile App
- `supabase_flutter` - Database Integration
- `provider` - State Management
- `flutter/material.dart` - UI Framework

## 🔗 API Endpoints

### Authentication
- `POST /api/auth/login` - Admin login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/change-password` - Change password

### Core Resources
- `GET/POST/PUT/DELETE /api/vendors` - Vendor management
- `GET/POST/PUT/DELETE /api/customers` - Customer management
- `GET/POST/PUT/DELETE /api/orders` - Order management
- `GET /api/dashboard/stats` - Dashboard statistics
- `GET /api/whatsapp/*` - WhatsApp integration
- `GET /api/commissions/*` - Commission tracking

## 🎯 Current Features Status

### ✅ Working
- Backend authentication (dev mode)
- Frontend routing and layout
- CORS configuration
- TypeScript compilation
- Basic dashboard API endpoints
- Development server setup

### 🚧 In Progress
- Dashboard UI implementation
- Data visualization components
- Real vendor/customer/order management
- Database integration
- Mobile app features

### ❌ Not Started
- Payment gateway integration
- WhatsApp Business API
- Advanced analytics
- File upload handling
- Email notifications

## 🐛 Known Issues
- Frontend shows placeholder data
- Dashboard components show "Coming Soon"
- No real database connection
- Mock authentication only works in development

---

**Last Updated**: 2025-12-17
**Maintainer**: Development Team