# Break the ZKP Protocol (Grand Challenge)

The various ZKP Protocols described below provide privacy on various aspects of a transaction on a public blockchain. The goal is to test the resilience ?? of these protocols.

## Aim of the Grand Challenge

There are products travelling through a supply process from supplier to manufacturer to retailer with transportation done by logistics provider. The aim is to find how many of what products are sent to manufacturer and then how many products of each does the manufacturer assemble to create how many number of final products. Also who has paid how much to whom for each of the service provided. The diagram below gives more details about the question.

![screenshot](screenshot.png "Question")

## What are the ZKP Protocols and what do they help accomplish?

Blockchains will do for networks of enterprises and business ecosystems what enterprise resource planning (ERP) did for the single company. We believe that the current model of siloed and parallel private networks is unsustainable as large companies seek to build overlapping, parallel networks. Rather, a future of large, regional or sector-specific public Ethereum networks is a more realistic future. To enable this future, in a public environment requires alternative ways to bring trust as full transparency is not acceptable for real business operations. It is not yet possible for companies to conduct secure, private transactions across the public Ethereum network.

In this work here, we use an approach that provides a solution using Zero Knowledge Proofs. Any asset that needs to be tracked is tokenised into a non-fungible token commitment while any payment that needs to be made against this asset is tokenised into a fungible token commitment. Processes are built over the movement of these token commitments using business logic executed through smart contracts. But to maintain privacy for business operations regarding what asset has been transferred between which two parties and how much was paid for it, we use 7 different ZKP protocols.

The zero knowledge proofs for these protocols are generated off chain while the verification of these proofs happens on chain.

The protocols are:

* **Fungible Token Mint** : Creates a fungible token commitment on the blockchain that holds value equivalent to the amount deposited to the `OpsCoinShield.sol` smart contract. The amount deposited can be in the form of any ERC20 token such as Ether. In this example, we use Dollar Tokens created using `OpsCoin.sol` for depositing.
Privacy - Minting is intended to be done from a known address and the value of minted coin is known. Nothing is revealed if any other transactions are done with this token after it is minted.

* **Fungible Token Transfer** : Any fungible token commitment can be transferred from owner to a recipient.
Privacy - Transferring is intended to be done from an anonymous address and the sender, the recipient as well as the value of the token transferred isn't revealed.

* **Fungible Token Burn** : Enables to withdraw the value held in a fungible token commitment back to an ERC20 token such as Ether or Dollar Tokens. In this example, Dollar tokens will be withdrawn.
Privacy - Burning is intended to be done from a public address and the amount withdrawn is known.

* **Non-Fungible Token Mint** : Creates a Non-Fungible token commitment on the blockchain that represents an asset by holding the asset hash derived from storing the asset's meta data on swarm.
Privacy - Minting is intended to be from a known address while the asset represented by the asset hash in the token commitment isn't revealed.

* **Non-Fungible Token Transfer** : Any Non-Fungible token commitment can be transferred from owner to a recipient.
Privacy - Transferring is intended to be done from an anonymous address and the sender, the recipient as well as the asset held by the token commitment aren't revealed.

* **Non-Fungible Token Join** : The assets stored on swarm are hierarchical in nature. This protocol enables an asset token commitment to be joined with another asset token commitment. The joined asset along with it's meta data is stored in swarm and a Non-Fungible token commitment is created on the blockchain using the resulting hash that represents this combined asset on the swarm while nullifying the original individual token commitments. Once joined, the new token commitment can be kept by the current owner or transferred to another recipient.
Privacy - The sender, recipient, first asset that was joined, second asset that was joined, the joined asset are not revealed.

* **Non-Fungible Token Split** : This protocol enables an asset token commitment to be split into multiple asset token commitments. These new assets along with their meta data are stored in swarm and Non-Fungible tokens commitments are created on the blockchain using the resulting hashes that represent these split assets on the swarm while nullifying the original token commitment. Once split, the new token commitments can be kept by the current owner or transferred to another recipient.
Privacy - The sender, recipient, original asset to be split, the assets after split are not revealed.

These protocols are used in the movement of any assets and payments on a public blockchain (Ethereum is used here) to ensure privacy.

## Contracts

* *Verifier.sol* : This smart contract verifies the zero knowledge proofs for all protocols specified above by taking the public inputs and returning a boolean based on success of failure

* *OpsCoin.sol* : This is an ERC20 compatible token smart contract that mints Public Dollar Tokens used in this example. Private Dollar Tokens can be minted by depositing these Public Dollar Tokens to the `OpsCoinShield.sol` smart contract. Also, Private Dollar tokens can be burnt to withdraw Public Dollar Tokens
using the same contract.

* *OpsCoinShield.sol* : This smart contract acts as a shield by enabling hiding fungible token commitments and their associated nullifiers. In order to mint, transfer or burn, a transaction is sent to this smart contract which then verifies the proof by calling `Verifier.sol` and adds the relevant token commitments to the token commitments list tree and nullifiers to the nullifiers list array.

* *TokenShield.sol* : This smart contract acts as a shield by enabling hiding non-fungible token commitments and their associated nullifiers. In order to mint, transfer, join or split, a transaction is sent to this smart contract which then verifies the proof by calling `Verifier.sol` and adds the relevant token commitments to the token commitments list tree, nullifiers to the nullifiers list array and double spend preventifiers to the double spend preventifiers list array. The double spend preventifier does what its called by ensuring no two token commitments hold the same asset.

## Components

**Swarm** - Swarm is used as an off chain distributed storage for asset meta data. The hash returned after storage of an asset in an encrypted manner is used to represent an asset uniquely and is used in making the token commitments that represent this asset.

The swarm public gateway run by Ethereum foundation is used here.
`https://swarm-gateways.net/`

## Information to follow the transactions on Ethereum

**List of Ethereum Addresses**
* Supplier 1
* Supplier 2
* Transport
* Manufacturer
* Retailer

**List of Anonymous Ethereum Addresses of the above players**
* Any address that calls transfer() in OpsCoinShield.sol and transfer(), join(), split() in TokenShield.sol

Other info ???

## Demo video
This video shows an overview with a GUI of the above mentioned protocols in action. This work is part of EY's OpsChain Public Edition product. OpsChain is a tokenisation based ecosystem level supply chain solution that provides various modules such as track and trace, inventory management etc ??

### Disclaimer ?? To Note
* The usage of fungible and non fungible is not to the specification of ERC20 and ERC720 standard. They are rather the commitments of these tokens represented by a 64 bit hash.
* It can be noted that inputs to proof verification are of 64 bits in length. This is not best practice considering brute force attacks. In the later iterations of this work, these will be changed to 256 bits.
* OpsCoin is not ERC20 compatible ???
* Zero Knowledge Circuits are not made public in this repository as they constitute EY's IP ???
* Various performance improvements can be made to make the contracts more cost efficient such as using trees in place of arrays to hold nullifiers or double spend preventifiers. Upcoming iterations of the work will address this.
* The maximum number of token commitments that the merkle tree holds is 256. The next iteration will make this number large for practical use.

Marketing EY

License

Delete any IP related comments from contracts
