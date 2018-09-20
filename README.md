# Break the ZKP Protocol (Grand Challenge)

## What are the ZKP Protocols and what do they help accomplish?

Blockchains will do for networks of enterprises and business ecosystems what enterprise resource planning (ERP) did for the single company. We believe that the current model of siloed and parallel private networks is unsustainable as large companies seek to build overlapping, parallel networks. Rather, a future of large, regional or sector-specific public Ethereum networks is a more realistic future. To enable this future, in a public environment requires alternative ways to bring trust as full transparency is not acceptable for real business operations. It is not yet possible for companies to conduct secure, private transactions across the public Ethereum network.

In this work here, we use an approach that provides a solution using Zero Knowledge Proofs. Any asset that needs to be tracked is tokenised into a non-fungible token while any payment that needs to be made against this asset is tokenised into a fungible token. Processes are built over the movement of these tokens using business logic executed through smart contracts. But to maintain privacy for business operations regarding what asset has been transferred between which two parties and how much was paid for it, we use 7 different ZKP protocols.

They are:

* Fungible Token Mint : Creates a fungible token on the blockchain that holds value equivalent to the amount deposited. The amount deposited can be in the form of any ERC20 token such as Ether. In this example, we use Dollar Tokens created using `OpsCoin.sol` for depositing. Privacy - Minting is intended to be done from a known address and the value of minted coin is known. Not much is revealed if any other transactions are done with this token after it is minted.

* Fungible Token Transfer : Any fungible token can be transferred from owner to a recipient. Privacy - Transferring is intended to be done from an anonymous address and the sender, the recipient as well as the value of the token transferred isn't revealed.

* Fungible Token Burn : Enables to withdraw the value held in a fungible token back to an ERC20 token such as Ether or Dollar Tokens. In this example, Dollar tokens will be withdrawn. Privacy - Burning is intended to be done from a public address and the amount withdrawn is known.

* Non-Fungible Token Mint : Creates a Non-Fungible token on the blockchain that represents an asset by holding the asset hash derived from storing the asset's meta data on swarm. Privacy - Minting is intended to be from a known address while the asset in the token represented by the asset hash isn't revealed.
* Non-Fungible Token Transfer : Any Non-Fungible token can be transferred from owner to a recipient. Privacy - Transferring is intended to be done from an anonymous address and the sender, the recipient as well as the asset held by the token isn't revealed.

* Non-Fungible Token Join : The assets stored on swarm are hierarchical in nature. This protocol enables an asset token to be joined with another asset token. This new asset along with it's meta data is stored in swarm and the resulting hash that represents this combined asset is stored as a Non-Fungible token on the blockchain while nullifying the tokens that represent the original tokens that were joined. Once joined, the new token can be kept by the current owner or transferred to another recipient. Privacy - The sender, recipient, first asset that was joined, second asset that was joined, the joined asset are not revealed.

* Non-Fungible Token Split : This protocol enables an asset token to be split into multiple asset tokens. These new assets along with their meta data are stored in swarm and the resulting hashes that represent these split assets are stored as Non-Fungible tokens on the blockchain while nullifying the token that represent the original token that was split. Once split, the new tokens can be kept by the current owner or transferred to another recipient. Privacy - The sender, recipient, original asset to be split, the assets after split are not revealed.

These protocols are used in the movement of any assets and payments on a public blockchain (Ethereum is used here) to ensure privacy.

![alt text](https://imgur.com/a/jV8ANef "Problem")
