import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const Commissions: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Commission Tracking
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          Commission tracking interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default Commissions;