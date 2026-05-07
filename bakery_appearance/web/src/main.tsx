import {createRoot} from 'react-dom/client';
import {StrictMode} from 'react';
import {MantineProvider} from '@mantine/core';
import './i18n';
import {VisibilityProvider} from './Providers/VisibilityProvider';
import {ConfigProvider} from './Providers/ConfigProvider';
import {AppearanceStoreProvider} from './Providers/AppearanceStoreProvider';
import {CustomizationProvider} from './Providers/CustomizationProvider';
import {App} from './Components/App';
import {AdminMenu} from './Components/AdminMenu';
import {DebugProvider} from './Providers/debug';
import {IsRunningInBrowser} from './Utils/Misc';
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <MantineProvider theme={{
      colorScheme: 'dark',
      fontFamily: '"Inter", sans-serif',
      /* 既定 × (1.2×テキスト / 1.4×root × 旧1.5×root) = 既定 × 9/7 … 旧1.5倍UI時の文字の1.2倍を維持 */
      fontSizes: {
        xs: '0.964rem',
        sm: '1.125rem',
        md: '1.286rem',
        lg: '1.446rem',
        xl: '1.607rem',
      },
      globalStyles: (theme) => ({
        body: {
          fontWeight: 500,
          WebkitFontSmoothing: 'antialiased',
          //MozOsxFontSmoothing: 'grayscale',
          textRendering: 'optimizeSpeed',
        fontSize: '1.286rem',
        },
        '*': {
          fontWeight: 500,
          WebkitFontSmoothing: 'antialiased',
          //MozOsxFontSmoothing: 'grayscale',
        }
      })
    }}>
      <CustomizationProvider>
        <ConfigProvider>
          <AppearanceStoreProvider>
            {IsRunningInBrowser() ? (
              <DebugProvider />
            ) : (
              <>
                <VisibilityProvider component='App'>
                  <App/>
                </VisibilityProvider>
                {/* Render AdminMenu outside App visibility so it can open independently */}
                <AdminMenu />
              </>
            )}
          </AppearanceStoreProvider>
        </ConfigProvider>
      </CustomizationProvider>
    </MantineProvider>
  </StrictMode>
);