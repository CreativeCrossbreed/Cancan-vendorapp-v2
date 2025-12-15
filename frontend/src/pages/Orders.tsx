import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const Orders: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Orders Management
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          Order management interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default Orders;