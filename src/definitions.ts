/**
 * Capacitor WeChat Plugin - WeChat SDK integration for authentication, sharing, payments, and mini-programs.
 *
 * @since 1.0.0
 */
export interface CapacitorWechatPlugin {
  /**
   * Initialize the WeChat SDK with your application credentials.
   *
   * You can also set these values in `capacitor.config.ts` under the `CapacitorWechat`
   * plugin configuration. Calling this method overrides any bundled configuration at runtime.
   *
   * @param options - Initialization options including the required WeChat App ID
   * @returns Promise that resolves when initialization completes
   * @throws Error if the App ID is missing or SDK initialization fails
   * @since 1.1.0
   * @example
   * ```typescript
   * await CapacitorWechat.initialize({
   *   appId: 'wx1234567890',
   *   universalLink: 'https://example.com/app/'
   * });
   * ```
   */
  initialize(options: WechatInitializationOptions): Promise<void>;

  /**
   * Check if WeChat app is installed on the device.
   *
   * @returns Promise that resolves with installation status
   * @throws Error if checking installation fails
   * @since 1.0.0
   * @example
   * ```typescript
   * const { installed } = await CapacitorWechat.isInstalled();
   * if (installed) {
   *   console.log('WeChat is installed');
   * }
   * ```
   */
  isInstalled(): Promise<{ installed: boolean }>;

  /**
   * Authenticate user with WeChat OAuth.
   *
   * @param options - Authentication options including scope
   * @returns Promise that resolves with authentication response containing code
   * @throws Error if authentication fails or is cancelled
   * @since 1.0.0
   * @example
   * ```typescript
   * const { code, state } = await CapacitorWechat.auth({
   *   scope: 'snsapi_userinfo',
   *   state: 'my_state'
   * });
   * // Use code to get access token from your server
   * ```
   */
  auth(options: WechatAuthOptions): Promise<WechatAuthResponse>;

  /**
   * Share content to WeChat.
   *
   * @param options - Share options including type, scene, and content
   * @returns Promise that resolves when sharing is complete
   * @throws Error if sharing fails or is cancelled
   * @since 1.0.0
   * @example
   * ```typescript
   * // Share text
   * await CapacitorWechat.share({
   *   scene: 0, // 0 = Session, 1 = Timeline, 2 = Favorite
   *   type: 'text',
   *   text: 'Hello WeChat!'
   * });
   *
   * // Share link
   * await CapacitorWechat.share({
   *   scene: 1,
   *   type: 'link',
   *   title: 'My Website',
   *   description: 'Check out my website',
   *   link: 'https://example.com',
   *   imageUrl: 'https://example.com/image.jpg'
   * });
   * ```
   */
  share(options: WechatShareOptions): Promise<void>;

  /**
   * Send payment request to WeChat Pay.
   *
   * @param options - Payment request options from server
   * @returns Promise that resolves when payment is complete
   * @throws Error if payment fails or is cancelled
   * @since 1.0.0
   * @example
   * ```typescript
   * // Get payment params from your server first
   * const paymentParams = await fetchPaymentParamsFromServer();
   *
   * await CapacitorWechat.sendPaymentRequest({
   *   partnerId: paymentParams.partnerId,
   *   prepayId: paymentParams.prepayId,
   *   nonceStr: paymentParams.nonceStr,
   *   timeStamp: paymentParams.timeStamp,
   *   package: paymentParams.package,
   *   sign: paymentParams.sign
   * });
   * ```
   */
  sendPaymentRequest(options: WechatPaymentOptions): Promise<void>;

  /**
   * Open WeChat mini-program.
   *
   * @param options - Mini-program options including username and path
   * @returns Promise that resolves with optional extra data from the mini-program
   * @throws Error if opening mini-program fails
   * @since 1.0.0
   * @example
   * ```typescript
   * const { extMsg } = await CapacitorWechat.openMiniProgram({
   *   username: 'gh_xxxxxxxxxxxxx',
   *   path: 'pages/index/index',
   *   type: 0 // 0 = Release, 1 = Test, 2 = Preview
   * });
   * ```
   */
  openMiniProgram(options: WechatMiniProgramOptions): Promise<{ extMsg?: string }>;

  /**
   * Choose invoice from WeChat.
   *
   * @param options - Invoice selection options
   * @returns Promise that resolves with selected invoice cards
   * @throws Error if selection fails or is cancelled
   * @since 1.0.0
   * @example
   * ```typescript
   * const { cards } = await CapacitorWechat.chooseInvoice({
   *   appId: 'your_app_id',
   *   signType: 'SHA1',
   *   cardSign: 'signature',
   *   timeStamp: '1234567890',
   *   nonceStr: 'random_string'
   * });
   * console.log('Selected cards:', cards);
   * ```
   */
  chooseInvoice(options: WechatInvoiceOptions): Promise<WechatInvoiceResponse>;

  /**
   * Get the native Capacitor plugin version.
   *
   * @returns Promise that resolves with the plugin version
   * @throws Error if getting the version fails
   * @since 1.0.0
   * @example
   * ```typescript
   * const { version } = await CapacitorWechat.getPluginVersion();
   * console.log('Plugin version:', version);
   * ```
   */
  getPluginVersion(): Promise<{ version: string }>;
}

/**
 * WeChat authentication options.
 */
export interface WechatAuthOptions {
  /**
   * OAuth scope. Use 'snsapi_userinfo' for user info or 'snsapi_login' for login only.
   */
  scope: string;

  /**
   * Optional state parameter for CSRF protection.
   */
  state?: string;
}

/**
 * WeChat authentication response.
 */
export interface WechatAuthResponse {
  /**
   * Authorization code to exchange for access token.
   */
  code: string;

  /**
   * State parameter if provided in request.
   */
  state?: string;
}

/**
 * WeChat share options.
 */
export interface WechatShareOptions {
  /**
   * Share scene: 0 = Session (chat), 1 = Timeline (moments), 2 = Favorite.
   */
  scene: number;

  /**
   * Share type: 'text', 'image', 'link', 'music', 'video', 'miniprogram'.
   */
  type: 'text' | 'image' | 'link' | 'music' | 'video' | 'miniprogram';

  /**
   * Text content (for type 'text').
   */
  text?: string;

  /**
   * Title (for type 'link', 'music', 'video', 'miniprogram').
   */
  title?: string;

  /**
   * Description (for type 'link', 'music', 'video', 'miniprogram').
   */
  description?: string;

  /**
   * Link URL (for type 'link').
   */
  link?: string;

  /**
   * Image URL or base64 data.
   */
  imageUrl?: string;

  /**
   * Thumbnail URL or base64 data (for type 'link', 'music', 'video').
   */
  thumbUrl?: string;

  /**
   * Music or video URL (for type 'music', 'video').
   */
  mediaUrl?: string;

  /**
   * Mini-program username (for type 'miniprogram').
   */
  miniProgramUsername?: string;

  /**
   * Mini-program path (for type 'miniprogram').
   */
  miniProgramPath?: string;

  /**
   * Mini-program type: 0 = Release, 1 = Test, 2 = Preview (for type 'miniprogram').
   */
  miniProgramType?: number;

  /**
   * Mini-program web page URL fallback (for type 'miniprogram').
   */
  miniProgramWebPageUrl?: string;
}

/**
 * WeChat payment options.
 */
export interface WechatPaymentOptions {
  /**
   * Partner ID (merchant ID).
   */
  partnerId: string;

  /**
   * Prepay ID from unified order API.
   */
  prepayId: string;

  /**
   * Random string.
   */
  nonceStr: string;

  /**
   * Timestamp.
   */
  timeStamp: string;

  /**
   * Package value, typically 'Sign=WXPay'.
   */
  package: string;

  /**
   * Signature.
   */
  sign: string;
}

/**
 * WeChat mini-program options.
 */
export interface WechatMiniProgramOptions {
  /**
   * Mini-program username (original ID).
   */
  username: string;

  /**
   * Path to open in mini-program.
   */
  path?: string;

  /**
   * Mini-program type: 0 = Release, 1 = Test, 2 = Preview.
   */
  type?: number;
}

/**
 * WeChat invoice options.
 */
export interface WechatInvoiceOptions {
  /**
   * App ID.
   */
  appId: string;

  /**
   * Signature type.
   */
  signType: string;

  /**
   * Card signature.
   */
  cardSign: string;

  /**
   * Timestamp.
   */
  timeStamp: string;

  /**
   * Random string.
   */
  nonceStr: string;
}

/**
 * WeChat invoice response.
 */
export interface WechatInvoiceResponse {
  /**
   * Array of selected card IDs.
   */
  cards: WechatInvoiceCard[];
}

/**
 * WeChat invoice card item.
 */
export interface WechatInvoiceCard {
  /**
   * The selected card identifier.
   */
  cardId: string;

  /**
   * Encrypted code returned by WeChat.
   */
  encryptCode?: string;
}

/**
 * WeChat initialization options.
 */
export interface WechatInitializationOptions {
  /**
   * Required WeChat application ID.
   */
  appId: string;

  /**
   * iOS universal link that is associated with your WeChat application.
   */
  universalLink?: string;
}
