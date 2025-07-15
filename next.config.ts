import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable standalone output for Docker
  output: 'standalone',
  
  // Experimental features
  experimental: {
    // Enable output file tracing for smaller Docker images
    outputFileTracingRoot: undefined,
  },
  
  // Additional config options
  poweredByHeader: false,
  
  // Environment variables that should be available at build time
  env: {
    NODE_ENV: process.env.NODE_ENV,
  },
};

export default nextConfig;
