"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

interface Props {
  params: {
    address: string;
  };
}

export default function InvestInPortfolio({ params }: Props) {
  return (
    <div className="relative flex items-center justify-center w-full">
      <div className="absolute top-4 left-4">
        <Link href="/">
          <Button className="bg-gray-800 py-1 hover:bg-gray-700">
            Back to all portfolios
          </Button>
        </Link>
      </div>

      <div className="w-full max-w-3xl border border-white p-4 mt-16">
        <div className="flex flex-col">
          <h2 className="text-lg">
            Replicate the DeFi portfolio of:
            <br />
            <b className="text-green-400 font-medium font-mono">
              {params.address}
            </b>
          </h2>

          <div className="w-full mt-6">
            <h4 className="font-medium text-lg">
              Target portfolio allocation:
            </h4>
            <ul className="list-disc ml-4 mt-2">
              <li>ETH: 53%</li>
              <li>DAI: 20%</li>
              <li>CRV: 27%</li>
            </ul>

            <div className="mt-4 flex gap-4">
              <Input type="text" placeholder="Amount in ETH" className="w-64" />
              <Button className="bg-gray-800 py-1 hover:bg-gray-700">
                Invest and Replicate!
              </Button>
            </div>

            <div className="mt-8">
              <h3 className="font-medium">How does this work?</h3>
              <p className="mt-2">
                By investing in this portfolio, your ETH will be swapped into
                the current portfolio allocations of the target address.
                <b>
                  Whenever the target address performs a trade and the
                  allocations change, your portfolio will be automatically
                  rebalanced
                </b>{" "}
                to match the new allocations.
              </p>

              <p className="mt-4">
                Under the hood, this uses a CoW Protocol Programmatic Order
                which can be triggered whenever the allocations change by more
                then the configured threshold (default: 5%).
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
