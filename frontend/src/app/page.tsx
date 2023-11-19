"use client";

import { useState } from "react";
import { useAccount, useConnect, useEnsName } from "wagmi";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { HomeTable } from "@/components/HomeTable";
import { fmtAddress } from "@/lib/utils";
import { InjectedConnector } from "wagmi/connectors/injected";

export default function Home() {
  const [safeAccount, setSafeAccount] = useState<string | null>(null);
  const [precalculatedSafeAccountAddress, setPrecalculatedSafeAccountAddress] =
    useState<string>("0x1f9090aaE28b8a3dCeaDf281B0F12828e676c326");

  const { address, isConnected } = useAccount();
  const { data: ensName } = useEnsName({ address });
  const { connect } = useConnect({
    connector: new InjectedConnector({ options: { shimDisconnect: true } }),
  });

  return (
    <div className="flex w-full">
      <div id="sidebar" className="border-gray-500 border-r w-64 h-screen">
        <div className="flex flex-col justify-between h-full w-full">
          <div className="mt-8 p-4 flex flex-col gap-4 items-center">
            {isConnected ? (
              <Button>{ensName ?? fmtAddress(address!)}</Button>
            ) : (
              <Button
                onClick={() => connect({ chainId: 5 })}
                className="border"
              >
                Connect wallet
              </Button>
            )}

            {safeAccount ? (
              <Badge className="bg-green-400 text-black rounded-xl hover:bg-green-300">
                Safe created
              </Badge>
            ) : (
              <Badge className="bg-white text-black rounded-xl hover:bg-gray-100">
                Creation pending
              </Badge>
            )}
            <div className="text-sm -mt-2 text-green-400">
              {fmtAddress(safeAccount || precalculatedSafeAccountAddress)}
            </div>
          </div>
        </div>
      </div>

      <div className="w-full">
        <div
          id="topbar"
          className="p-4 flex w-full items-center justify-between border-b border-gray-500"
        >
          <div></div>
          <div className="flex gap-4 items-center"></div>
        </div>

        <div id="content" className="p-4">
          <h1 className="text-2xl font-medium">
            Start your <b className="text-green-400">Replication</b> journey!
          </h1>

          <div className="mt-8 border border-white p-1">
            <HomeTable />
          </div>
        </div>
      </div>
    </div>
  );
}
