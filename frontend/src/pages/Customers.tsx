import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const Customers: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Customers Management
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          Customer management interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default Customers;