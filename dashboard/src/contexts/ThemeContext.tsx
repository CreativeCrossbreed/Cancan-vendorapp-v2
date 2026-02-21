import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';
import { createTheme, Theme } from '@mui/material/styles';
import { PaletteMode } from '@mui/material';

interface ThemeContextType {
  mode: PaletteMode;
  toggleColorMode: () => void;
  theme: Theme;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const useThemeContext = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useThemeContext must be used within ThemeProvider');
  }
  return context;
};

const getDesignTokens = (mode: PaletteMode) => ({
  palette: {
    mode,
    primary: {
      main: '#3b82f6',
      light: '#60a5fa',
      dark: '#2563eb',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: '#10b981',
      light: '#34d399',
      dark: '#059669',
    },
    error: {
      main: '#ef4444',
    },
    warning: {
      main: '#f59e0b',
    },
    info: {
      main: '#3b82f6',
    },
    success: {
      main: '#10b981',
    },
    ...(mode === 'light'
      ? {
          background: {
            default: '#f8fafc',
            paper: '#ffffff',
          },
          text: {
            primary: '#0f172a',
            secondary: '#64748b',
            disabled: '#94a3b8',
          },
          divider: '#e2e8f0',
        }
      : {
          background: {
            default: '#0f172a',
            paper: '#1e293b',
          },
          text: {
            primary: '#f1f5f9',
            secondary: '#94a3b8',
            disabled: '#64748b',
          },
          divider: '#334155',
        }),
  },
  typography: {
    fontFamily: '"Inter", "Poppins", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: { fontWeight: 700, fontSize: '2.25rem' },
    h2: { fontWeight: 700, fontSize: '1.875rem' },
    h3: { fontWeight: 600, fontSize: '1.5rem' },
    h4: { fontWeight: 600, fontSize: '1.25rem' },
    h5: { fontWeight: 600, fontSize: '1.125rem' },
    h6: { fontWeight: 600, fontSize: '1rem' },
    subtitle1: { fontWeight: 500 },
    subtitle2: { fontWeight: 500 },
    body1: { fontWeight: 400 },
    body2: { fontWeight: 400 },
    button: { fontWeight: 500, textTransform: 'none' },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: ({ theme }: { theme: Theme }) => ({
          borderRadius: 16,
          boxShadow: theme.palette.mode === 'dark'
            ? '0 4px 12px rgba(0,0,0,0.3)'
            : '0 2px 8px rgba(0,0,0,0.06)',
          backgroundColor: theme.palette.background.paper,
        }),
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: ({ theme }: { theme: Theme }) => ({
          backgroundImage: 'none',
          backgroundColor: theme.palette.background.paper,
        }),
        elevation1: ({ theme }: { theme: Theme }) => ({
          boxShadow: theme.palette.mode === 'dark'
            ? '0 2px 8px rgba(0,0,0,0.2)'
            : '0 1px 3px rgba(0,0,0,0.08)',
        }),
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 10,
          fontWeight: 500,
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 4px 12px rgba(59, 130, 246, 0.3)',
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 500,
          borderRadius: 8,
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: ({ theme }: { theme: Theme }) => ({
          borderBottom: `1px solid ${theme.palette.divider}`,
        }),
        head: ({ theme }: { theme: Theme }) => ({
          fontWeight: 600,
          color: theme.palette.text.primary,
          backgroundColor: theme.palette.mode === 'dark' ? '#1e293b' : '#f1f5f9',
        }),
      },
    },
    MuiTableRow: {
      styleOverrides: {
        root: ({ theme }: { theme: Theme }) => ({
          '&:hover': {
            backgroundColor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.03)' : '#f8fafc',
          },
        }),
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: ({ theme }: { theme: Theme }) => ({
          boxShadow: theme.palette.mode === 'dark'
            ? '0 1px 3px rgba(0,0,0,0.3)'
            : '0 1px 3px rgba(0,0,0,0.06)',
        }),
      },
    },
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          scrollbarColor: '#cbd5e1 #f1f5f9',
          '&::-webkit-scrollbar, & *::-webkit-scrollbar': {
            width: 8,
            height: 8,
          },
          '&::-webkit-scrollbar-thumb, & *::-webkit-scrollbar-thumb': {
            borderRadius: 8,
            backgroundColor: '#cbd5e1',
            minHeight: 24,
          },
          '&::-webkit-scrollbar-thumb:hover, & *::-webkit-scrollbar-thumb:hover': {
            backgroundColor: '#94a3b8',
          },
          '&::-webkit-scrollbar-track, & *::-webkit-scrollbar-track': {
            backgroundColor: '#f1f5f9',
          },
        },
      },
    },
  },
});

interface ThemeProviderProps {
  children: React.ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const [mode, setMode] = useState<PaletteMode>(() => {
    const savedMode = localStorage.getItem('theme-mode');
    return (savedMode === 'dark' ? 'dark' : 'light') as PaletteMode;
  });

  useEffect(() => {
    localStorage.setItem('theme-mode', mode);
  }, [mode]);

  const toggleColorMode = () => {
    setMode((prevMode) => (prevMode === 'light' ? 'dark' : 'light'));
  };

  const theme = useMemo(() => createTheme(getDesignTokens(mode)), [mode]);

  const value = useMemo(
    () => ({
      mode,
      toggleColorMode,
      theme,
    }),
    [mode, theme]
  );

  return (
    <ThemeContext.Provider value={value}>
      <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
    </ThemeContext.Provider>
  );
};
