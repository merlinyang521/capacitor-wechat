import { WebPlugin } from '@capacitor/core';

import type {
  CapacitorWechatPlugin,
  WechatAuthOptions,
  WechatAuthResponse,
  WechatShareOptions,
  WechatPaymentOptions,
  WechatMiniProgramOptions,
  WechatInvoiceOptions,
  WechatInvoiceResponse,
} from './definitions';

export class CapacitorWechatWeb extends WebPlugin implements CapacitorWechatPlugin {
  async initialize(): Promise<void> {
    throw this.unavailable('initialize is not available on the web.');
  }

  isInstalled(): Promise<{ installed: boolean }> {
    return Promise.resolve({ installed: false });
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  auth(_options: WechatAuthOptions): Promise<WechatAuthResponse> {
    throw new Error('Method not implemented on web platform.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  share(_options: WechatShareOptions): Promise<void> {
    throw new Error('Method not implemented on web platform.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  sendPaymentRequest(_options: WechatPaymentOptions): Promise<void> {
    throw new Error('Method not implemented on web platform.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  openMiniProgram(_options: WechatMiniProgramOptions): Promise<{ extMsg?: string }> {
    throw new Error('Method not implemented on web platform.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  chooseInvoice(_options: WechatInvoiceOptions): Promise<WechatInvoiceResponse> {
    throw new Error('Method not implemented on web platform.');
  }

  async getPluginVersion(): Promise<{ version: string }> {
    return { version: 'web' };
  }
}
