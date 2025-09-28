const ROOT_URL =
  process.env.NEXT_PUBLIC_URL ||
  (process.env.VERCEL_URL && `https://${process.env.VERCEL_URL}`) ||
  "http://localhost:3000";

/**
 * MiniApp configuration object. Must follow the mini app manifest specification.
 *
 * @see {@link https://docs.base.org/mini-apps/features/manifest}
 */
export const minikitConfig = {
  accountAssociation: {
    header: "eyJmaWQiOjEzMTA4NDcsInR5cGUiOiJjdXN0b2R5Iiwia2V5IjoiMHhENTZBRWVmMDg5MDlkQWQ1ZjRiYzZhNWVGRTgxMDI0MjA0NjQzMTA5In0",
    payload: "eyJkb21haW4iOiJtaW5pYXBwLW1lZXQ0LnZlcmNlbC5hcHAifQ",
    signature: "MHgwMGQ0NGM1ZDdmYjNkNzkxNzFiMGY0ZDdiZTlkMTYxYmE2ZjNlOThlMjQ1ZDYwNjJhZWJmZmM2MzdjMjIwYzQzMGFiMWNkZmNkYjM2NDUzMjVhNTU0MzcxYWMxNzRiYTQ2YTExZjBmYjcxY2Q3N2ViY2QyMzMxOTJkZDhkMTM0MzFi",
  },
  baseBuilder: {
    allowedAddresses: ["0xdEbae18f9d4951b284582d44d7692777bE01CA65"],
  },
  miniapp: {
    version: "1",
    name: "my-minikit-app",
    subtitle: "test",
    description: "test",
    screenshotUrls: [`${ROOT_URL}/screenshot1.png`],
    iconUrl: `${ROOT_URL}/icon.png`,
    splashImageUrl: `${ROOT_URL}/splash.png`,
    splashBackgroundColor: "#000000",
    homeUrl: ROOT_URL,
    webhookUrl: `${ROOT_URL}/api/webhook`,
    primaryCategory: "utility",
    tags: ["example"],
    heroImageUrl: `${ROOT_URL}/hero.png`,
    tagline: "test",
    ogTitle: "test",
    ogDescription: "test",
    ogImageUrl: `${ROOT_URL}/hero.png`,
  },
} as const;
