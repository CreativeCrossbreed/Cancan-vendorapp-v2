# Can Can Vendor Admin Dashboard

A comprehensive ERE (Express, React, Node) stack admin dashboard for managing the Can Can water can delivery vendor ecosystem with WhatsApp API integration.

## Features

### Backend (Node.js + Express)
- ✅ RESTful API with TypeScript
- ✅ JWT Authentication with role-based access
- ✅ Supabase database integration
- ✅ WhatsApp webhook handler for automated orders
- ✅ CRUD operations for vendors, customers, and orders
- ✅ Commission tracking system
- ✅ Real-time WebSocket support

### Frontend (React + TypeScript)
- ✅ Material-UI v5 components
- ✅ Redux Toolkit for state management
- ✅ Protected routes and authentication
- ✅ Responsive design
- ✅ Dashboard with real-time statistics

## Tech Stack

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **TypeScript** - Type safety
- **Supabase** - Database and backend-as-a-service
- **JWT** - Authentication tokens
- **Socket.io** - Real-time communication
- **WhatsApp Business API** - Customer order processing

### Frontend
- **React 18** - UI framework
- **TypeScript** - Type safety
- **Material-UI (MUI) v5** - Component library
- **Redux Toolkit** - State management
- **React Router v6** - Routing
- **Axios** - HTTP client

## Quick Start

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- Supabase account
- WhatsApp Business API access (optional)

### Backend Setup

1. Navigate to backend directory
```bash
cd backend
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Set up database schema
```sql
-- Run the database_schema.sql file in your Supabase project
```

5. Start the backend server
```bash
npm run dev
```

Backend will run on `http://localhost:5000`

### Frontend Setup

1. Navigate to frontend directory
```bash
cd frontend
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Start the frontend application
```bash
npm start
```

Frontend will run on `http://localhost:3000`

## Default Login Credentials

- **Email**: admin@cancan.com
- **Password**: admin123

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login admin
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/change-password` - Change password

### Dashboard
- `GET /api/dashboard/stats` - Get dashboard statistics
- `GET /api/dashboard/revenue` - Get revenue analytics
- `GET /api/dashboard/top-vendors` - Get top performing vendors

### Vendors
- `GET /api/vendors` - List vendors with pagination
- `GET /api/vendors/:id` - Get vendor details
- `POST /api/vendors` - Create new vendor
- `PUT /api/vendors/:id` - Update vendor
- `DELETE /api/vendors/:id` - Delete vendor

### Customers
- `GET /api/customers` - List customers
- `GET /api/customers/:id` - Get customer details
- `POST /api/customers` - Create new customer
- `PUT /api/customers/:id` - Update customer

### Orders
- `GET /api/orders` - List orders with filters
- `GET /api/orders/:id` - Get order details
- `PUT /api/orders/:id/status` - Update order status
- `POST /api/orders` - Create manual order

### WhatsApp
- `POST /api/whatsapp/webhook` - WhatsApp webhook endpoint
- `GET /api/whatsapp/messages` - Get message logs
- `GET /api/whatsapp/orders` - Get WhatsApp orders
- `POST /api/whatsapp/send` - Send custom message

### Commissions
- `GET /api/commissions` - List commission records
- `POST /api/commissions` - Create commission record
- `PUT /api/commissions/:id/status` - Update commission status

## WhatsApp Integration

The system includes a complete WhatsApp Business API integration:

1. **Automated Order Detection**: The system parses incoming WhatsApp messages to detect orders
2. **Order Confirmation**: Automatic confirmation messages are sent to customers
3. **Customer Verification**: Customers must be registered before placing orders
4. **Order Assignment**: Orders are automatically assigned to available vendors

### Example WhatsApp Order Flow:
1. Customer sends: "I need 2 water cans"
2. System detects order and verifies customer
3. Order is created and assigned to vendor
4. Customer receives confirmation with order details

## Commission System

Track and manage vendor commissions:
- Automatic commission calculation on completed orders
- Configurable commission rates per vendor
- Payment status tracking
- Commission reports and analytics

## Environment Variables

### Backend (.env)
```
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
```
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_WHATSAPP_WEBHOOK_URL=https://your-domain.com/api/whatsapp/webhook
```

## Development

### Backend Scripts
- `npm run dev` - Start development server with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Start production server

### Frontend Scripts
- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests

## Production Deployment

### Backend
1. Build the TypeScript code
2. Set production environment variables
3. Deploy to your preferred hosting (Heroku, AWS, DigitalOcean)
4. Configure webhook endpoint URL in WhatsApp Business API

### Frontend
1. Build the React application
2. Deploy to static hosting (Vercel, Netlify, AWS S3)
3. Update API URL in environment variables

## Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- Rate limiting on API endpoints
- Input validation and sanitization
- WhatsApp webhook signature verification
- CORS protection
- SQL injection prevention

## Monitoring and Analytics

- Real-time dashboard statistics
- Vendor performance metrics
- Order analytics
- WhatsApp message tracking
- Commission reporting
- System health monitoring

## Support

For any issues or questions:
1. Check the console logs for detailed error messages
2. Verify all environment variables are set correctly
3. Ensure Supabase connection is working
4. Check WhatsApp API credentials if using WhatsApp features

## License

This project is proprietary to Can Can Water Can Delivery Service.