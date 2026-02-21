// Temporary fix for Material-UI Grid component issues
// This provides backward compatibility with older Grid syntax

import { Grid, GridProps } from '@mui/material';
import React from 'react';

// Create a wrapper Grid component that maintains backward compatibility
export const GridFix: React.FC<GridProps> = ({ children, ...props }) => {
  return (
    <Grid {...props}>
      {children}
    </Grid>
  );
};

export default GridFix;