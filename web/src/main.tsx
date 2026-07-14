import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { isEnvBrowser } from './nui';
import './styles.css';

if (isEnvBrowser()) {
  void import('./mock').then((m) => m.installMock());
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
