"use client";

import { WagmiConfig, configureChains, createConfig } from "wagmi";
import { goerli } from "viem/chains";
import { publicProvider } from "wagmi/providers/public";
import { Toaster } from "@/components/ui/toaster";

// la spazzatura globale
export let safeAddress: string | null = null;

export function setSafeAddress(address: string) {
  safeAddress = address;
}

const { publicClient, webSocketPublicClient } = configureChains(
  [goerli],
  [publicProvider()]
);

const config = createConfig({
  autoConnect: true,
  publicClient,
  webSocketPublicClient,
});

export default function RootProviders({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <WagmiConfig config={config}>
      <main>{children}</main>
      <Toaster />
    </WagmiConfig>
  );
}
