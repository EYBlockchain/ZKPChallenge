/**
@notice © Copyright 2018 EYGS LLP and/or other members of the global Ernst & Young/EY network; pat. pending.

@title OpsCoinShield V1

Contract to enable the management of ZKSnark-hidden coin transactions. Currently it can
only cope with commitments that are 8 bytes long. A normal tokenhash is 32 bytes long
TODO - need to cope with the other 24 bytes and have a deeper Merkle tree
*/

pragma solidity ^0.4.19;
import "./OpsCoin.sol";
contract Verifier{
  function verifyTx(
          uint[2],
          uint[2],
          uint[2][2],
          uint[2],
          uint[2],
          uint[2],
          uint[2],
          uint[2],
          address
          ) public pure returns (bool){}
  function getInputBits(uint, address) public view returns(bytes8){}
}

contract OpsCoinShield{
  address public owner;
  bytes8[merkleWidth] ns; //store spent token nullifiers
  uint constant merkleWidth = 256;
  uint constant merkleDepth = 9;
  uint constant lastRow = merkleDepth-1;
  uint private balance = 0;
  bytes8[merkleWidth] private zs; //array holding the commitments.  Basically the bottom row of the merkle tree
  uint private zCount; //remember the number of commitments we hold
  uint private nCount; //remember the number of commitments we spent
  bytes8[] private roots; //holds each root we've calculated so that we can pull the one relevant to the prover
  uint private currentRootIndex; //holds the index for the current root so that the
  //prover can provide it later and this contract can look up the relevant root
  Verifier private mv; //the verification smart contract that the mint function uses
  Verifier private sv; //the verification smart contract that the transfer function uses
  OpsCoin private ops; //the OpsCoin ERC20 token contract
  struct Proof { //recast this as a struct because otherwise, as a set of local variable, it takes too much stack space
    uint[2] a;
    uint[2] a_p;
    uint[2][2] b;
    uint[2] b_p;
    uint[2] c;
    uint[2] c_p;
    uint[2] h;
    uint[2] k;
  }
  //Proof proof; //not used - proof is now set per address
  mapping(address => Proof) private proofs;

  constructor(address mintVerifier, address transferVerifier, address opsCoin) public {
    // TODO - you can get a way with a single, generic verifier.
    owner = msg.sender;
    mv = Verifier(mintVerifier);
    sv = Verifier(transferVerifier);
    ops = OpsCoin(opsCoin);
  }

  //only owner  modifier
  modifier onlyOwner () {
      require(msg.sender == owner);
      _;
  }

  /**
  self destruct added by westlad
  */
  function close() public onlyOwner {
        selfdestruct(owner);
    }


  function getMintVerifier() public view returns(address){
    return address(mv);
  }

  function getTransferVerifier() public view returns(address){
    return address(sv);
  }

  function getOpsCoin() public view returns(address){
    return address(ops);
  }

  /**
  The mint function accepts opscoin and creates the same amount as a commitment.
    */
  function mint(uint amount) public {
    //first, verify the proof

    bool result = mv.verifyTx(
      proofs[msg.sender].a,
      proofs[msg.sender].a_p,
      proofs[msg.sender].b,
      proofs[msg.sender].b_p,
      proofs[msg.sender].c,
      proofs[msg.sender].c_p,
      proofs[msg.sender].h,
      proofs[msg.sender].k,
      msg.sender);

    require(result); //the proof must check out
    //transfer OPS from the sender to this contract
    ops.transferFrom(msg.sender, address(this), amount);
    //save the commitments
    bytes8 z = mv.getInputBits(64, msg.sender);//recover the input params from MintVerifier
    zs[zCount++] = z; //add the token
    require(uint(mv.getInputBits(0, msg.sender))==amount); //check we've been correctly paid
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  /**
  The transfer function transfers a commitment to a new owner
  */
  function transfer() public {
    //verification contract
    bool result = sv.verifyTx(
      proofs[msg.sender].a,
      proofs[msg.sender].a_p,
      proofs[msg.sender].b,
      proofs[msg.sender].b_p,
      proofs[msg.sender].c,
      proofs[msg.sender].c_p,
      proofs[msg.sender].h,
      proofs[msg.sender].k,
      msg.sender);
    require(result); //the proof must verify. The spice must flow.

    bytes8 nc = sv.getInputBits(0, msg.sender);
    bytes8 nd = sv.getInputBits(64, msg.sender);
    bytes8 ze = sv.getInputBits(128, msg.sender);
    bytes8 zf = sv.getInputBits(192, msg.sender);
    for (uint i=0; i<nCount; i++) { //check this is an unspent coin
      require(ns[i]!=nc && ns[i]!=nd);
    }
    ns[nCount++] = nc; //remember we spent it
    ns[nCount++] = nd; //remember we spent it
    zs[zCount++] = ze; //add Bob's commitment to the list of commitments
    zs[zCount++] = zf; //add Alice's commitment to the list of commitment
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  function burn(address payTo) public {
    //first, verify the proof
    bool result = mv.verifyTx(
      proofs[msg.sender].a,
      proofs[msg.sender].a_p,
      proofs[msg.sender].b,
      proofs[msg.sender].b_p,
      proofs[msg.sender].c,
      proofs[msg.sender].c_p,
      proofs[msg.sender].h,
      proofs[msg.sender].k,
      msg.sender);

    require(result); //the proof must check out ok
    //transfer OPS from this contract to the nominated address
    bytes8 C = mv.getInputBits(0, msg.sender);//recover the coin value
    uint256 value = uint256(C); //convert the coin value to a uint
    ops.transfer(payTo, value); //and pay the man
    bytes8 Nc = mv.getInputBits(64, msg.sender); //recover the nullifier
    ns[nCount++] = Nc; //add the nullifier to the list of nullifiers
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  /**
  This function is only needed because mint and transfer otherwise use too many
  local variables for the limited stack space, rather than pass a proof as
  parameters to these functions (more logical)
  */
  function setProofParams(
      uint[2] a,
      uint[2] a_p,
      uint[2][2] b,
      uint[2] b_p,
      uint[2] c,
      uint[2] c_p,
      uint[2] h,
      uint[2] k)
      public {
    //TODO there must be a shorter way to do this:
    proofs[msg.sender].a[0] = a[0];
    proofs[msg.sender].a[1] = a[1];
    proofs[msg.sender].a_p[0] = a_p[0];
    proofs[msg.sender].a_p[1] = a_p[1];
    proofs[msg.sender].b[0][0] = b[0][0];
    proofs[msg.sender].b[0][1] = b[0][1];
    proofs[msg.sender].b[1][0] = b[1][0];
    proofs[msg.sender].b[1][1] = b[1][1];
    proofs[msg.sender].b_p[0] = b_p[0];
    proofs[msg.sender].b_p[1] = b_p[1];
    proofs[msg.sender].c[0] = c[0];
    proofs[msg.sender].c[1] = c[1];
    proofs[msg.sender].c_p[0] = c_p[0];
    proofs[msg.sender].c_p[1] = c_p[1];
    proofs[msg.sender].h[0] = h[0];
    proofs[msg.sender].h[1] = h[1];
    proofs[msg.sender].k[0] = k[0];
    proofs[msg.sender].k[1] = k[1];
  }

  function getTokens() public view returns(bytes8[merkleWidth], uint root) {
    //need the commitments to compute a proof and also an index to look up the current
    //root.
    return (zs,currentRootIndex);
  }

  /**
  Function to return the root that was current at rootIndex
  */
  function getRoot(uint rootIndex) view public returns(bytes8) {
    return roots[rootIndex];
  }

  function computeMerkle() public view returns (bytes8){//for backwards compat
    return merkle(0,0);
  }

  function merkle(uint r, uint t) public view returns (bytes8) {
    //This is a recursive approach, which seems efficient but we do end up
    //calculating the whole tree from scratch each time.  Need to look at storing
    //intermediate values and seeing if that will make it cheaper.
    if (r==lastRow) {
      return zs[t];
    } else {
      return bytes8(sha256(merkle(r+1,2*t)^merkle(r+1,2*t+1))<<192);
    }
  }
}
