import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  AppBar,
  Toolbar,
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Stack
} from '@mui/material';
import WaterDropIcon from '@mui/icons-material/WaterDrop';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import NotificationsActiveIcon from '@mui/icons-material/NotificationsActive';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';

const FeatureCard: React.FC<{ icon: React.ReactNode; title: string; description: string }> = ({ icon, title, description }) => {
  return (
    <Card elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
      <CardContent>
        <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 1 }}>
          <Box sx={{ p: 1, borderRadius: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
            {icon}
          </Box>
          <Typography variant="h6" sx={{ fontWeight: 700 }}>{title}</Typography>
        </Stack>
        <Typography variant="body2" sx={{ color: 'text.secondary' }}>{description}</Typography>
      </CardContent>
    </Card>
  );
};

const Landing: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box>
      <AppBar elevation={0} position="static" color="inherit" sx={{ borderBottom: '1px solid', borderColor: 'divider' }}>
        <Toolbar sx={{ py: 1.5 }}>
          <Stack direction="row" spacing={1.5} alignItems="center" sx={{ flexGrow: 1 }}>
            <WaterDropIcon color="primary" />
            <Typography variant="h6" sx={{ fontWeight: 800 }}>Can Can</Typography>
          </Stack>
          <Stack direction="row" spacing={2} alignItems="center">
            <Button color="inherit" onClick={() => navigate('/login')}>Login</Button>
            <Button variant="contained" onClick={() => navigate('/login')} sx={{ borderRadius: 2, fontWeight: 700 }}>
              Vendor Portal
            </Button>
          </Stack>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 10 } }}>
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' },
            columnGap: { xs: 3, md: 6 },
            rowGap: 6,
            alignItems: 'center',
          }}
        >
          <Box>
            <Typography variant="overline" sx={{ color: 'primary.main', fontWeight: 800, letterSpacing: 1.2 }}>
              Water Delivery, Done Right
            </Typography>
            <Typography variant="h3" sx={{ fontWeight: 900, lineHeight: 1.1, mt: 1 }}>
              Fast, Reliable Water Can Delivery For Your Neighborhood
            </Typography>
            <Typography variant="body1" sx={{ color: 'text.secondary', mt: 2 }}>
              Can Can connects customers with nearby vendors for quick water can deliveries. Smart routing, automated WhatsApp ordering, and a powerful vendor portal.
            </Typography>
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mt: 3 }}>
              <Button size="large" variant="contained" onClick={() => navigate('/login')} sx={{ borderRadius: 2, fontWeight: 700 }}>
                Vendor Login
              </Button>
              <Button size="large" variant="outlined" onClick={() => navigate('/login')} sx={{ borderRadius: 2, fontWeight: 700 }}>
                Join As Vendor
              </Button>
            </Stack>
          </Box>
          <Box>
            <Box
              sx={{
                borderRadius: 4,
                border: '1px solid',
                borderColor: 'divider',
                p: 3,
                background: 'linear-gradient(135deg, rgba(33,150,243,0.08) 0%, rgba(0,200,83,0.08) 100%)'
              }}
            >
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                <Box>
                  <FeatureCard
                    icon={<LocalShippingIcon />}
                    title="Smart Dispatch"
                    description="Assign orders to the best vendor based on proximity and availability."
                  />
                </Box>
                <Box>
                  <FeatureCard
                    icon={<NotificationsActiveIcon />}
                    title="WhatsApp First"
                    description="Click-to-Chat QR onboarding and interactive ordering. No app needed."
                  />
                </Box>
                <Box>
                  <FeatureCard
                    icon={<VerifiedUserIcon />}
                    title="Reliable"
                    description="Secure, serverless infrastructure with real-time sync powered by Supabase."
                  />
                </Box>
                <Box>
                  <FeatureCard
                    icon={<WaterDropIcon />}
                    title="Built For Scale"
                    description="From single neighborhoods to city-wide operations, we’ve got you."
                  />
                </Box>
              </Box>
            </Box>
          </Box>
        </Box>

        <Box sx={{ mt: 10 }}>
          <Typography variant="h5" sx={{ fontWeight: 800, mb: 2 }}>
            How It Works
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 3 }}>
            <Box>
              <Card elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                <CardContent>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>
                    1. Customer scans QR
                  </Typography>
                  <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                    Each vendor has a unique QR for WhatsApp onboarding with pre-filled messages.
                  </Typography>
                </CardContent>
              </Card>
            </Box>
            <Box>
              <Card elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                <CardContent>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>
                    2. Interactive ordering
                  </Typography>
                  <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                    Customers tap buttons in WhatsApp to pick quantity and delivery time.
                  </Typography>
                </CardContent>
              </Card>
            </Box>
            <Box>
              <Card elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                <CardContent>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1 }}>
                    3. Vendor fulfills
                  </Typography>
                  <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                    Orders sync to the vendor app with local notifications and real-time updates.
                  </Typography>
                </CardContent>
              </Card>
            </Box>
          </Box>
        </Box>
      </Container>

      <Box sx={{ borderTop: '1px solid', borderColor: 'divider', py: 4 }}>
        <Container maxWidth="lg">
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" justifyContent="space-between">
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              © {new Date().getFullYear()} Can Can. All rights reserved.
            </Typography>
            <Button size="small" onClick={() => navigate('/login')}>Vendor Login</Button>
          </Stack>
        </Container>
      </Box>
    </Box>
  );
};

export default Landing;
