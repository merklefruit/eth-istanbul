"use client";

import { useState } from "react";
import {
  useAccount,
  useConnect,
  useContractWrite,
  useDisconnect,
  useEnsName,
  usePrepareContractWrite,
} from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
import { Button } from "@/components/ui/button";
import { HomeTable } from "@/components/HomeTable";
import { useToast } from "@/components/ui/use-toast";
import SafeFactory from "@/abi/SafeFactory.json";
import { SAFE_FACTORY_ADDRESS } from "@/lib/consts";
import { fmtAddress } from "@/lib/utils";

export default function Home() {
  const [safeAccount, setSafeAccount] = useState<string | null>(null);

  const { toast } = useToast();
  const { address, isConnected } = useAccount();
  const { data: ensName } = useEnsName({ address });
  const { disconnect } = useDisconnect();
  const { connect } = useConnect({
    connector: new InjectedConnector({ options: { shimDisconnect: true } }),
  });

  const { config: createSafeConfig } = usePrepareContractWrite({
    address: SAFE_FACTORY_ADDRESS,
    abi: SafeFactory.abi,
    functionName: "createSafe",
  });
  const { write: createSafe } = useContractWrite(createSafeConfig);

  return (
    <div className="flex w-full">
      <div id="sidebar" className="border-gray-500 border-r w-64 h-screen">
        <div className="flex flex-col justify-between h-full w-full">
          <div className="mt-8 p-4 flex flex-col gap-4 items-center">
            {isConnected ? (
              <Button
                onClick={() => {
                  disconnect();
                  toast({ title: "Wallet disconnected!" });
                }}
              >
                {ensName ?? fmtAddress(address!)}
              </Button>
            ) : (
              <Button
                onClick={() => {
                  connect({ chainId: 5 });
                  toast({ title: "Wallet connected to Goerli!" });
                }}
                className="border"
              >
                Connect wallet
              </Button>
            )}

            {address && (
              <>
                {safeAccount ? (
                  <Button className="bg-green-400 text-black rounded-xl hover:bg-green-300">
                    Safe created
                  </Button>
                ) : (
                  <Button
                    onClick={() => createSafe?.()}
                    className="bg-white text-black hover:bg-gray-100 rounded-xl"
                  >
                    Create Safe
                  </Button>
                )}
                <div className="text-sm -mt-2 text-green-400">
                  {/* {fmtAddress(safeAccount || precalculatedSafeAccountAddress)} */}
                </div>
              </>
            )}
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
            You're a bad trader? Just{" "}
            <b className="text-green-400">Replicate</b> the pros!
          </h1>

          <div className="mt-8 border border-white p-1">
            <HomeTable />
          </div>
        </div>
      </div>
    </div>
  );
}
