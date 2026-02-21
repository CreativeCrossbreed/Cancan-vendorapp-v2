import dotenv from 'dotenv';
// Load environment variables before importing database config
dotenv.config();

import './config/database'; // Ensure database connection is initialized
import { server } from './app';

const PORT = process.env.PORT || 5000;

console.log('🚀 Can Can Admin Dashboard Backend Starting...');
console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);

server.listen(PORT, () => {
  console.log(`📡 Backend server running on port ${PORT}`);
  console.log(`🌍 API URL: http://localhost:${PORT}`);
});