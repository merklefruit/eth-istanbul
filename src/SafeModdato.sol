import {Safe} from "safe-contracts/Safe.sol";
import {ExtensibleFallbackHandler} from "safe-contracts/handler/ExtensibleFallbackHandler.sol";
import {ISafeSignatureVerifier} from "safe-contracts/handler/extensible/SignatureVerifierMuxer.sol";

interface MiniRebalanceOrder {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

contract SafeModdato is Safe, ExtensibleFallbackHandler {
    // We change the fallback handler to the Cow Protocol and then, using the Extensible Fallback
    // Handler interface (from forked version of safe smart contracts, via rndLabs),
    // we can update the domain separator and the verifier address
    constructor(address rebalanceOrder) {
        address fallbackHandler = address(
            0x2f55e8b20D0B9FEFA187AA7d00B6Cbe563605bF5
        );
        setFallbackHandler(fallbackHandler);

        bytes32 domainSeparator = MiniRebalanceOrder(rebalanceOrder)
            .DOMAIN_SEPARATOR();

        setDomainVerifier(
            domainSeparator,
            ISafeSignatureVerifier(0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74)
        );
    }
}
