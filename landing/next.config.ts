import path from "node:path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // 404 propia para las dos raíces (español e inglés).
  experimental: { globalNotFound: true },
  turbopack: {
    // La landing es su propio proyecto dentro del monorepo (studio/ es Flutter).
    root: path.join(__dirname),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
