import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const WhatsApp: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        WhatsApp Integration
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          WhatsApp API management interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default WhatsApp;