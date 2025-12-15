import React from 'react';
import { Typography, Box, Paper } from '@mui/material';

const Settings: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Settings
      </Typography>
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography>
          System settings interface - Coming soon!
        </Typography>
      </Paper>
    </Box>
  );
};

export default Settings;