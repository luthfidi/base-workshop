import type { NextConfig } from "next";

const nextConfig = {
  async redirects() {
    return [
      {
        source: "/about",
        destination: "https://api.farcaster.xyz/miniapps/hosted-manifest/01998e9f-cc97-572c-017a-67f9a12a091a",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
