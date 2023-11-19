const COMPOSABLE_COW_GOERLI = "0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74";
const DOMAIN_SEPARATOR_GOERLI =
  "0xfb378b35457022ecc5709ae5dafad9393c1387ae6d8ce24913a0c969074c07fb";
const CHAIN_ID_GOERLI = "5";

export function safeModder(safeAccount: string) {
  return {
    version: "1.0",
    chainId: CHAIN_ID_GOERLI,
    createdAt: 1700336687590,
    meta: {
      name: "Test",
      description: "",
      txBuilderVersion: "1.16.3",
      createdFromSafeAddress: "0x5b7e5386d19C44be87d4a07858304874ae67DAbA",
      createdFromOwnerAddress: "",
      checksum:
        "0x9572b545a0648b4d41baa05cb9eadf4323fd5c2097b2d6f6d94e71e87a3aa6b3",
    },
    transactions: [
      {
        to: safeAccount,
        value: "0",
        data: null,
        contractMethod: {
          inputs: [
            {
              internalType: "address",
              name: "handler",
              type: "address",
            },
          ],
          name: "setFallbackHandler",
          payable: false,
        },
        contractInputsValues: {
          handler: "0x2f55e8b20D0B9FEFA187AA7d00B6Cbe563605bF5",
        },
      },
      {
        to: safeAccount,
        value: "0",
        data: null,
        contractMethod: {
          inputs: [
            {
              internalType: "bytes32",
              name: "domainSeparator",
              type: "bytes32",
            },
            {
              internalType: "contract ISafeSignatureVerifier",
              name: "newVerifier",
              type: "address",
            },
          ],
          name: "setDomainVerifier",
          payable: false,
        },
        contractInputsValues: {
          domainSeparator: DOMAIN_SEPARATOR_GOERLI,
          newVerifier: "0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74",
        },
      },
      {
        // Approve sell token: this will approve spending of the sell token by the fallback handler
        to: "0x1111111111111111111111111111111111111111",
        value: "0",
        data: null,
        contractMethod: {
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          name: "approve",
          payable: false,
        },
        contractInputsValues: {
          spender: "0xC92E8bdf79f0507f65a392b0ab4667716BFE0110",
          value:
            "115792089237316195423570985008687907853269984665640564039457584007913129639935",
        },
      },
      {
        to: COMPOSABLE_COW_GOERLI,
        value: "0",
        data: null,
        contractMethod: {
          inputs: [
            {
              components: [
                {
                  internalType: "contract IConditionalOrder",
                  name: "handler",
                  type: "address",
                },
                {
                  internalType: "bytes32",
                  name: "salt",
                  type: "bytes32",
                },
                {
                  internalType: "bytes",
                  name: "staticInput",
                  type: "bytes",
                },
              ],
              internalType: "struct IConditionalOrder.ConditionalOrderParams",
              name: "params",
              type: "tuple",
            },
            {
              internalType: "bool",
              name: "dispatch",
              type: "bool",
            },
          ],
          name: "create",
          payable: false,
        },
        contractInputsValues: {
          params:
            '["0x2222222222222222222222222222222222222222","0x5555555555555555555555555555555555555555555555555555555555555555","0xbaddad"]',
          dispatch: "true",
        },
      },
    ],
  };
}
