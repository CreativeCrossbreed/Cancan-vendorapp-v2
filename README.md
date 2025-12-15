# Can Can Water Can Delivery Platform

A comprehensive water can delivery platform consisting of three main components: a Flutter vendor mobile app, a React admin dashboard, and a Node.js/Express backend with WhatsApp integration.

## 🏗️ Monorepo Structure

```
vendor_app/
├── cancanapp/                # Flutter vendor mobile app
│   ├── lib/                 # Flutter source code
│   ├── android/             # Android platform files
│   ├── ios/                 # iOS platform files
│   ├── pubspec.yaml         # Flutter dependencies
│   └── ...
├── admin-dashboard/          # React admin dashboard
│   ├── backend/             # Node.js/Express API server
│   │   ├── src/             # TypeScript source code
│   │   ├── dist/            # Compiled JavaScript
│   │   ├── package.json     # Node.js dependencies
│   │   └── ...
│   └── frontend/            # React admin app
│       ├── src/             # React source code
│       ├── public/          # Static assets
│       ├── package.json     # Node.js dependencies
│       └── ...
├── .gitignore              # Git ignore file for all projects
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- **Flutter** (SDK >=3.0.0) for the vendor app
- **Node.js** (v16 or higher) for backend and frontend
- **npm** or **yarn** package manager
- **Supabase** account for database and backend services
- **WhatsApp Business API** access (optional for WhatsApp features)

## 📱 Flutter Vendor App (cancanapp/)

### Setup

1. Navigate to vendor app directory:
```bash
cd cancanapp
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit with your Supabase credentials
```

4. Run the app (requires connected device or emulator):
```bash
flutter run
```

### Features

- 🔐 **Phone-based Authentication** - Secure OTP verification via Supabase
- 📱 **Real-time Order Management** - View and update order statuses
- 📊 **Dashboard Analytics** - Daily earnings and delivery summaries
- 📦 **Inventory Tracking** - Monitor stock levels and product availability
- 💰 **Payment Tracking** - Track paid and unpaid orders
- 🏖️ **Vacation Mode** - Temporarily pause order acceptance
- 📄 **QR Code Generation** - Easy customer ordering via QR codes
- 🔄 **Real-time Updates** - Order status changes via Supabase Realtime

### Development Commands

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
```

## 🖥️ Admin Dashboard (admin-dashboard/)

### Backend Setup

1. Navigate to backend directory:
```bash
cd admin-dashboard/backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run database migrations (SQL provided in `database_schema.sql`)

5. Start the development server:
```bash
npm run dev
```

The backend API will run on `http://localhost:5000`

### Frontend Setup

1. Navigate to frontend directory:
```bash
cd admin-dashboard/frontend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your backend URL
```

4. Start the development server:
```bash
npm start
```

The admin dashboard will run on `http://localhost:3000`

### Features

- **Dashboard Analytics**: Real-time statistics and KPIs
- **Vendor Management**: CRUD operations, performance tracking, commission rates
- **Customer Management**: Customer directory, order history, analytics
- **Order Management**: View all orders, assign to vendors, status updates
- **WhatsApp Integration**: Manage message logs, send custom messages
- **Commission Tracking**: Automatic calculation, payment status, reporting
- **Role-based Access**: Multi-level admin permissions
- **Real-time Updates**: WebSocket integration for live data

### Default Admin Credentials

- **Email**: admin@cancan.com
- **Password**: admin123

## 🔧 Backend API Features

- **RESTful API**: Complete CRUD operations for all entities
- **WhatsApp Webhooks**: Automated order processing from WhatsApp
- **Authentication**: JWT-based with role-based access control
- **Real-time Communication**: WebSocket support
- **Commission System**: Automatic calculation and tracking
- **File Upload**: Support for vendor documents and images
- **Rate Limiting**: API protection against abuse
- **Comprehensive Logging**: Structured logging for monitoring

## 📱 WhatsApp Integration

The platform includes a sophisticated WhatsApp Business API integration:

1. **Automated Order Detection**: Parses incoming messages to identify orders
2. **Customer Verification**: Ensures only registered customers can place orders
3. **Order Assignment**: Automatically assigns orders to available vendors
4. **Confirmation Messages**: Sends detailed order confirmations
5. **Status Updates**: Real-time delivery status notifications
6. **Payment Reminders**: Automated payment collection messages

### Example Order Flow:
```
Customer: "I need 2 water cans"
System: ✓ Detects order, verifies customer
System: ✓ Creates order, assigns to nearest vendor
System: ✓ Sends confirmation with order details
```

## 💳 Commission System

- **Automatic Calculation**: Commissions calculated on completed orders
- **Flexible Rates**: Configure commission rates per vendor
- **Payment Tracking**: Monitor paid and pending commissions
- **Reporting**: Generate commission statements and analytics
- **Bulk Operations**: Process multiple commission payments

## 🗄️ Database Schema

The platform uses Supabase with the following main tables:

- **vendors**: Vendor information and profiles
- **customers**: Customer directory
- **products**: Product catalog
- **orders**: Order management
- **order_items**: Order line items
- **vendor_products**: Vendor-specific pricing
- **commission_records**: Commission tracking
- **whatsapp_messages**: WhatsApp message logs
- **admin_users**: Admin authentication

## 🔧 Environment Configuration

### Backend (.env)
```env
PORT=5000
NODE_ENV=development

# Supabase
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anonymous_key

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=7d

# WhatsApp API
WHATSAPP_API_TOKEN=your_whatsapp_api_token
WHATSAPP_PHONE_NUMBER_ID=your_whatsapp_phone_number_id
WHATSAPP_WEBHOOK_SECRET=your_webhook_secret
WHATSAPP_BUSINESS_ACCOUNT_ID=your_business_account_id

# Frontend URL
FRONTEND_URL=http://localhost:3000
```

### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_WHATSAPP_WEBHOOK_URL=https://your-domain.com/api/whatsapp/webhook
```

### Flutter (.env)
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anonymous_key
```

## 🚀 Deployment

### Backend
1. Build TypeScript: `npm run build`
2. Deploy to your preferred platform (Heroku, AWS, DigitalOcean)
3. Configure production environment variables
4. Set up webhook URL in WhatsApp Business API

### Frontend
1. Build React app: `npm run build`
2. Deploy to static hosting (Vercel, Netlify, AWS S3)
3. Update API URL in production environment

### Flutter App
1. Build APK: `flutter build apk`
2. Build iOS: `flutter build ios`
3. Upload to respective app stores

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt for secure password storage
- **Rate Limiting**: API endpoint protection
- **Input Validation**: Comprehensive validation and sanitization
- **CORS Protection**: Cross-origin resource sharing controls
- **Webhook Verification**: WhatsApp webhook signature validation
- **SQL Injection Prevention**: Parameterized queries
- **Environment Security**: Sensitive data in environment variables

## 📊 Monitoring and Analytics

- **Dashboard Statistics**: Real-time KPIs and metrics
- **Vendor Performance**: Track delivery efficiency and ratings
- **Customer Analytics**: Order patterns and preferences
- **Revenue Tracking**: Financial performance monitoring
- **WhatsApp Analytics**: Message success rates and engagement
- **System Health**: API response times and error tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 🐛 Troubleshooting

### Common Issues

1. **Backend won't start**: Check environment variables and database connection
2. **Frontend API errors**: Verify backend URL in .env file
3. **Flutter build issues**: Run `flutter clean` then `flutter pub get`
4. **WhatsApp not working**: Check API credentials and webhook setup
5. **Database errors**: Run migration scripts and verify Supabase schema

## 📄 License

This project is proprietary to Can Can Water Can Delivery Service.

## 📞 Support

For technical support:
1. Check the console logs for detailed error messages
2. Verify all environment variables are configured correctly
3. Ensure Supabase connection is active
4. Check WhatsApp API status if using WhatsApp features

---

### Technologies Used

- **Flutter** - Mobile app development
- **React** - Frontend dashboard
- **Node.js/Express** - Backend API
- **TypeScript** - Type safety
- **Supabase** - Database and auth
- **WhatsApp Business API** - Customer communication
- **Material-UI** - React components
- **Redux Toolkit** - State management

### Code Quality

- Follow Flutter's official style guide
- Use `flutter analyze` to check for issues
- Write tests for new features
- Use the logger instead of print statements
- Follow ESLint rules for React/Node code