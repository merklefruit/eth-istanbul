import { ethers } from "ethers";
import { EthersAdapter } from "@safe-global/protocol-kit";
import SafeApiKit from "@safe-global/api-kit";
import Safe from "@safe-global/protocol-kit";

export function useSafe() {
  async function getSafe(safeAddress: string): Promise<Safe> {
    const web3Provider = new ethers.providers.Web3Provider(
      (window as any).ethereum
    );
    const ethAdapter = new EthersAdapter({
      ethers,
      signerOrProvider: web3Provider.getSigner(),
    });

    const safeApiKit = new SafeApiKit({
      txServiceUrl: "https://safe-transaction-goerli.safe.global",
      ethAdapter,
    });

    const safe = await Safe.create({
      ethAdapter,
      safeAddress,
    });

    return safe;
  }

  return {
    getSafe,
  };
}
