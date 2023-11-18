import {Safe} from "lib/safe-contracts/contracts/Safe.sol";
import {ExtensibleFallbackHandler} from "lib/safe-contracts/contracts/handler/ExtensibleFallbackHandler.sol";

contract SafeModdato is Safe {
    // We change the fallback handler to the Cow Protocol and then, using the Extensible Fallback Handler interface (from forked version of safe smart contracts, via rndLabs),we can update the domain separator and the verifier address
    constructor(address rebalanceOrder) {
        address ExtensibleFallbackHandler = address(
            0x2f55e8b20D0B9FEFA187AA7d00B6Cbe563605bF5
        );
        setFallbackHandler(ExtensibleFallbackHandler);
    }
}
