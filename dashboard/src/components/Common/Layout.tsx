import React, { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  AppBar,
  Box,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Avatar,
  Menu,
  MenuItem,
  Badge,
  Tooltip,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard,
  People,
  ShoppingCart,
  WhatsApp,
  Payments,
  Settings,
  Logout,
  Notifications,
  ExpandLess,
  ExpandMore,
  LightMode,
  DarkMode,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../../store';
import { logout } from '../../store/authSlice';
import { useThemeContext } from '../../contexts/ThemeContext';

const DRAWER_WIDTH_EXPANDED = 260;
const DRAWER_WIDTH_COLLAPSED = 80;

const menuItems = [
  { text: 'Dashboard', icon: <Dashboard />, path: '/dashboard' },
  { text: 'Vendors', icon: <People />, path: '/vendors' },
  { text: 'Customers', icon: <People />, path: '/customers' },
  { text: 'Orders', icon: <ShoppingCart />, path: '/orders' },
  { text: 'WhatsApp', icon: <WhatsApp />, path: '/whatsapp' },
  { text: 'Commissions', icon: <Payments />, path: '/commissions' },
  { text: 'Settings', icon: <Settings />, path: '/settings' },
];

const Layout: React.FC = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [isCollapsed, setIsCollapsed] = useState(true);
  const [isHovered, setIsHovered] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch<AppDispatch>();
  const { user } = useSelector((state: RootState) => state.auth);
  const { mode, toggleColorMode, theme } = useThemeContext();
  const isLargeScreen = useMediaQuery(theme.breakpoints.up('lg'));

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    dispatch(logout());
    navigate('/login');
  };

  const isExpanded = !isCollapsed || isHovered;
  const drawerWidth = isExpanded ? DRAWER_WIDTH_EXPANDED : DRAWER_WIDTH_COLLAPSED;

  // Sidebar colors based on theme
  const sidebarBg = mode === 'dark' ? '#0f172a' : '#1e293b';
  const sidebarBorder = mode === 'dark' ? 'rgba(255, 255, 255, 0.06)' : 'rgba(255, 255, 255, 0.08)';
  const contentBg = theme.palette.background.default;
  const headerBg = theme.palette.background.paper;
  const headerBorder = theme.palette.divider;

  // Sidebar Content
  const sidebarContent = (
    <Box
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        bgcolor: sidebarBg,
        border: 'none',
      }}
    >
      {/* Logo/Brand Section */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: isExpanded ? 'flex-start' : 'center',
          px: isExpanded ? 2.5 : 0,
          py: 3,
          height: 72,
          borderBottom: `1px solid ${sidebarBorder}`,
        }}
      >
        <Box
          sx={{
            width: 42,
            height: 42,
            borderRadius: 3,
            background: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            boxShadow: '0 4px 12px rgba(59, 130, 246, 0.4)',
          }}
        >
          <WhatsApp sx={{ color: 'white', fontSize: 24 }} />
        </Box>
        {isExpanded && (
          <Box sx={{ ml: 2 }}>
            <Typography
              variant="h6"
              noWrap
              sx={{
                fontWeight: 800,
                color: '#ffffff',
                lineHeight: 1.2,
                fontSize: '1.35rem',
                letterSpacing: '-0.5px',
              }}
            >
              Can Can
            </Typography>
            <Typography
              variant="caption"
              noWrap
              sx={{
                color: 'rgba(255, 255, 255, 0.6)',
                fontSize: '0.7rem',
                fontWeight: 500,
              }}
            >
              Vendor Portal
            </Typography>
          </Box>
        )}
      </Box>

      {/* Navigation Items */}
      <Box sx={{ flex: 1, py: 2, overflowY: 'auto', overflowX: 'hidden' }}>
        <List sx={{ px: isExpanded ? 1.5 : 0, py: 0 }}>
          {menuItems.map((item) => {
            const isSelected = location.pathname === item.path;
            return (
              <Tooltip
                key={item.text}
                title={!isExpanded ? item.text : ''}
                placement="right"
                arrow
                disableHoverListener={isExpanded}
                TransitionProps={{ timeout: 0 }}
              >
                <ListItem disablePadding sx={{ mb: 0.5 }}>
                  <ListItemButton
                    selected={isSelected}
                    onClick={() => navigate(item.path)}
                    sx={{
                      borderRadius: isExpanded ? 2 : 1.5,
                      minHeight: 52,
                      px: isExpanded ? 2 : 0,
                      py: 1.25,
                      justifyContent: isExpanded ? 'flex-start' : 'center',
                      transition: 'all 0.25s ease-in-out',
                      position: 'relative',
                      overflow: 'hidden',
                      ...(isSelected && {
                        background: 'linear-gradient(90deg, rgba(59, 130, 246, 0.25) 0%, rgba(59, 130, 246, 0.05) 100%)',
                        borderLeft: isExpanded ? '3px solid #3b82f6' : 'none',
                        '&:hover': {
                          background: 'linear-gradient(90deg, rgba(59, 130, 246, 0.3) 0%, rgba(59, 130, 246, 0.08) 100%)',
                        },
                      }),
                      ...(!isSelected && {
                        '&:hover': {
                          bgcolor: 'rgba(255, 255, 255, 0.08)',
                        },
                      }),
                    }}
                  >
                    {isSelected && !isExpanded && (
                      <Box
                        sx={{
                          position: 'absolute',
                          left: 0,
                          top: '50%',
                          transform: 'translateY(-50%)',
                          width: 4,
                          height: '60%',
                          bgcolor: '#3b82f6',
                          borderRadius: '0 4px 4px 0',
                        }}
                      />
                    )}
                    <ListItemIcon
                      sx={{
                        minWidth: 0,
                        color: isSelected ? '#3b82f6' : 'rgba(255, 255, 255, 0.7)',
                        justifyContent: 'center',
                        mr: isExpanded ? 2 : 0,
                        '& .MuiSvgIcon-root': {
                          fontSize: 22,
                        },
                      }}
                    >
                      {item.icon}
                    </ListItemIcon>
                    {isExpanded && (
                      <ListItemText
                        primary={item.text}
                        sx={{
                          '& .MuiTypography-root': {
                            fontWeight: isSelected ? 600 : 500,
                            fontSize: '0.9rem',
                            color: isSelected ? '#ffffff' : 'rgba(255, 255, 255, 0.8)',
                            letterSpacing: '0.15px',
                          },
                        }}
                      />
                    )}
                  </ListItemButton>
                </ListItem>
              </Tooltip>
            );
          })}
        </List>
      </Box>

      {/* Collapse Toggle at Bottom */}
      <Box
        sx={{
          px: isExpanded ? 2 : 0,
          py: 2,
          borderTop: `1px solid ${sidebarBorder}`,
        }}
      >
        <Tooltip
          title={isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
          placement="right"
          arrow
          disableHoverListener={isExpanded}
        >
          <IconButton
            onClick={() => setIsCollapsed(!isCollapsed)}
            sx={{
              width: isExpanded ? '100%' : 48,
              height: 48,
              justifyContent: 'center',
              bgcolor: isExpanded ? 'rgba(255, 255, 255, 0.06)' : 'transparent',
              borderRadius: 2,
              transition: 'all 0.2s ease',
              '&:hover': {
                bgcolor: 'rgba(255, 255, 255, 0.12)',
              },
            }}
          >
            {isExpanded ? (
              <ExpandLess sx={{ color: 'rgba(255, 255, 255, 0.7)' }} />
            ) : (
              <ExpandMore sx={{ color: 'rgba(255, 255, 255, 0.7)' }} />
            )}
          </IconButton>
        </Tooltip>
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', bgcolor: contentBg, minHeight: '100vh' }}>
      {/* Desktop Sidebar - Expandable with Hover */}
      <Drawer
        variant="permanent"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        sx={{
          display: { xs: 'none', lg: 'block' },
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
            bgcolor: sidebarBg,
            borderRight: 'none',
            overflowX: 'hidden',
            transition: 'width 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            zIndex: 1100,
            boxShadow: '4px 0 24px rgba(0, 0, 0, 0.15)',
          },
        }}
        open
      >
        {sidebarContent}
      </Drawer>

      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={handleDrawerToggle}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: 'block', lg: 'none' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: DRAWER_WIDTH_EXPANDED,
            bgcolor: sidebarBg,
            borderRight: 'none',
          },
        }}
      >
        {sidebarContent}
      </Drawer>

      {/* Main Content Wrapper */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { lg: `calc(100% - ${drawerWidth}px)` },
          display: 'flex',
          flexDirection: 'column',
          minHeight: '100vh',
          transition: 'width 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        }}
      >
        {/* Top Header Bar */}
        <AppBar
          position="fixed"
          sx={{
            width: { lg: `calc(100% - ${drawerWidth}px)` },
            ml: { lg: `${drawerWidth}px` },
            bgcolor: headerBg,
            color: 'text.primary',
            boxShadow: mode === 'dark' ? '0 1px 3px rgba(0, 0, 0, 0.3)' : '0 1px 3px rgba(0, 0, 0, 0.06)',
            borderBottom: `1px solid ${headerBorder}`,
            height: 64,
            zIndex: 1000,
            transition: 'width 0.3s cubic-bezier(0.4, 0, 0.2, 1), margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          }}
        >
          <Toolbar
            sx={{
              minHeight: '64px !important',
              px: { xs: 2, sm: 3 },
            }}
          >
            <IconButton
              color="inherit"
              aria-label="open drawer"
              edge="start"
              onClick={handleDrawerToggle}
              sx={{
                mr: 2,
                display: { lg: 'none' },
                bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#f1f5f9',
                '&:hover': { bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.12)' : '#e2e8f0' },
              }}
            >
              <MenuIcon />
            </IconButton>

            {/* Page Title */}
            <Box sx={{ flexGrow: 1 }}>
              <Typography
                variant="h6"
                noWrap
                sx={{
                  fontWeight: 700,
                  color: theme.palette.text.primary,
                  fontSize: '1.25rem',
                }}
              >
                {menuItems.find((item) => item.path === location.pathname)?.text || 'Dashboard'}
              </Typography>
            </Box>

            {/* Right Actions */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              {/* Dark Mode Toggle */}
              <IconButton
                onClick={toggleColorMode}
                sx={{
                  borderRadius: 2.5,
                  width: 42,
                  height: 42,
                  bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#f1f5f9',
                  '&:hover': {
                    bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.12)' : '#e2e8f0',
                  },
                }}
              >
                {mode === 'dark' ? (
                  <LightMode sx={{ color: '#fbbf24', fontSize: 20 }} />
                ) : (
                  <DarkMode sx={{ color: theme.palette.text.secondary, fontSize: 20 }} />
                )}
              </IconButton>

              {/* Notifications */}
              <IconButton
                color="inherit"
                sx={{
                  borderRadius: 2.5,
                  width: 42,
                  height: 42,
                  bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#f1f5f9',
                  '&:hover': {
                    bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.12)' : '#e2e8f0',
                  },
                }}
              >
                <Badge badgeContent={3} color="error" max={99}>
                  <Notifications sx={{ color: theme.palette.text.secondary, fontSize: 20 }} />
                </Badge>
              </IconButton>

              {/* User Menu */}
              <IconButton
                size="small"
                aria-label="account of current user"
                aria-controls="menu-appbar"
                aria-haspopup="true"
                onClick={handleMenu}
                sx={{
                  borderRadius: 2.5,
                  width: 42,
                  height: 42,
                  bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#f1f5f9',
                  '&:hover': {
                    bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.12)' : '#e2e8f0',
                  },
                  ml: 1,
                }}
              >
                <Avatar
                  sx={{
                    width: 28,
                    height: 28,
                    bgcolor: '#3b82f6',
                    fontWeight: 600,
                    fontSize: '0.85rem',
                  }}
                >
                  {user?.email?.charAt(0).toUpperCase() || 'A'}
                </Avatar>
              </IconButton>

              <Menu
                id="menu-appbar"
                anchorEl={anchorEl}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                keepMounted
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                open={Boolean(anchorEl)}
                onClose={handleClose}
                PaperProps={{
                  sx: {
                    minWidth: 220,
                    mt: 1.5,
                    borderRadius: 2.5,
                    boxShadow: mode === 'dark' ? '0 10px 40px rgba(0,0,0,0.4)' : '0 10px 40px rgba(0,0,0,0.15)',
                    border: `1px solid ${theme.palette.divider}`,
                    overflow: 'visible',
                    bgcolor: theme.palette.background.paper,
                  },
                }}
              >
                <MenuItem
                  disabled
                  sx={{
                    opacity: 1,
                    py: 2,
                    bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.03)' : '#f8fafc',
                    borderBottom: `1px solid ${theme.palette.divider}`,
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar
                      sx={{
                        width: 40,
                        height: 40,
                        bgcolor: '#3b82f6',
                        fontWeight: 600,
                      }}
                    >
                      {user?.email?.charAt(0).toUpperCase() || 'A'}
                    </Avatar>
                    <Box>
                      <Typography
                        variant="body2"
                        sx={{ fontWeight: 600, color: theme.palette.text.primary, fontSize: '0.9rem' }}
                      >
                        {user?.email || 'Admin'}
                      </Typography>
                      <Typography
                        variant="caption"
                        sx={{ color: theme.palette.text.secondary, fontSize: '0.8rem' }}
                      >
                        {user?.email}
                      </Typography>
                    </Box>
                  </Box>
                </MenuItem>
                <MenuItem
                  onClick={handleLogout}
                  sx={{
                    py: 1.5,
                    px: 2,
                    mt: 0.5,
                    borderRadius: 1,
                    mx: 1,
                    color: '#ef4444',
                    '&:hover': { bgcolor: mode === 'dark' ? 'rgba(239, 68, 68, 0.1)' : '#fef2f2' },
                  }}
                >
                  <Logout fontSize="small" sx={{ color: '#ef4444', mr: 2 }} />
                  <Typography sx={{ fontWeight: 500 }}>Logout</Typography>
                </MenuItem>
              </Menu>
            </Box>
          </Toolbar>
        </AppBar>

        {/* Page Content Area */}
        <Box
          sx={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            bgcolor: contentBg,
          }}
        >
          {/* Spacer for fixed header */}
          <Toolbar sx={{ minHeight: '64px !important' }} />

          {/* Main Content */}
          <Box
            sx={{
              flex: 1,
              px: { xs: 2, sm: 3, md: 4 },
              py: 3,
              maxWidth: '100%',
            }}
          >
            <Outlet />
          </Box>

          {/* Footer */}
          <Box
            component="footer"
            sx={{
              borderTop: `1px solid ${theme.palette.divider}`,
              bgcolor: theme.palette.background.paper,
              px: { xs: 2, sm: 3, md: 4 },
              py: 3,
              mt: 'auto',
            }}
          >
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: 2,
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Box
                  sx={{
                    width: 32,
                    height: 32,
                    borderRadius: 2,
                    background: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <WhatsApp sx={{ color: 'white', fontSize: 16 }} />
                </Box>
                <Box>
                  <Typography
                    variant="body2"
                    sx={{ fontWeight: 600, color: theme.palette.text.primary, fontSize: '0.85rem' }}
                  >
                    Can Can Vendor Portal
                  </Typography>
                  <Typography
                    variant="caption"
                    sx={{ color: theme.palette.text.secondary, fontSize: '0.75rem' }}
                  >
                    © 2024 All rights reserved
                  </Typography>
                </Box>
              </Box>

              <Box
                sx={{
                  display: 'flex',
                  gap: 0.5,
                  bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.05)' : '#f1f5f9',
                  borderRadius: 2,
                  p: 0.5,
                }}
              >
                {['Privacy', 'Terms', 'Support'].map((item) => (
                  <Typography
                    key={item}
                    variant="body2"
                    sx={{
                      color: theme.palette.text.secondary,
                      cursor: 'pointer',
                      px: 2,
                      py: 0.75,
                      borderRadius: 1.5,
                      fontSize: '0.8rem',
                      fontWeight: 500,
                      transition: 'all 0.2s',
                      '&:hover': {
                        color: '#3b82f6',
                        bgcolor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#ffffff',
                      },
                    }}
                  >
                    {item}
                  </Typography>
                ))}
              </Box>
            </Box>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default Layout;
