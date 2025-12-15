import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const Vendors: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Vendors Management
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          Vendor management interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default Vendors;