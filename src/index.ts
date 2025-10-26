import { registerPlugin } from '@capacitor/core';

import type { CapacitorWechatPlugin } from './definitions';

const CapacitorWechat = registerPlugin<CapacitorWechatPlugin>('CapacitorWechat', {
  web: () => import('./web').then((m) => new m.CapacitorWechatWeb()),
});

export * from './definitions';
export { CapacitorWechat };
