/*
Contract to enable the management of hidden Token transactions. Currently it can
only cope with tokens that are 8 bytes long. A normal tokenhash is 32 bytes long
TODO - need to cope with the other 24 bytes
*/
pragma solidity ^0.4.19;
import "./OpsCoin.sol";
//TODO - you can get a way with a single, generic verifier.
contract Verifier{
  function verifyTx(
          uint[2],
          uint[2],
          uint[2][2],
          uint[2],
          uint[2],
          uint[2],
          uint[2],
          uint[2]
          ) public pure returns (bool){}
  function getInputBits(uint) public view returns(bytes8){}
}

contract OpsCoinShield{
  bytes8[merkleWidth] ns; //store spent token nullifiers
  uint constant merkleWidth = 256;
  uint constant merkleDepth = 9;
  uint constant lastRow = merkleDepth-1;
  uint balance = 0;
  bytes8[merkleWidth] private zs; //array holding the tokens.  Basically the bottom row of the merkle tree
  uint private zCount; //remember the number of tokens we hold
  uint private nCount; //remember the number of tokens we spent
  bytes8[] private roots; //holds each root we've calculated so that we can pull the one relevant to the prover
  uint public currentRootIndex; //holds the index for the current root so that the
  //prover can provide it later and this contract can look up the relevant root
  Verifier mv; //the verification smart contract that the mint function uses
  Verifier sv; //the verification smart contract that the transfer function uses
  OpsCoin ops; //the OpsCoin ERC20 token contract
  //uint i; //just a loop counter, should be local but moved here to preserve stack space
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
  Proof proof;

  constructor(address mintVerifier, address transferVerifier, address opsCoin) public {
      mv = Verifier(mintVerifier);
      sv = Verifier(transferVerifier);
      ops = OpsCoin(opsCoin);
  }

  function getMintVerifier() returns(address){
    return address(mv);
  }

  function getTransferVerifier() returns(address){
    return address(sv);
  }

  function getOpsCoin() returns(address){
    return address(ops);
  }

  /**
  The mint function accepts creates a z-coin.
    */
  function mint(uint amount, bytes32 tId) public {
    //first, verify the proof

    bool result = mv.verifyTx(
      proof.a,
      proof.a_p,
      proof.b,
      proof.b_p,
      proof.c,
      proof.c_p,
      proof.h,
      proof.k);

    require(result); //the proof must check out
    //transfer OPS from the sender to this contract
    ops.enableTransaction(tId,msg.sender,address(this),1,amount,true,false);
    ops.transferById(tId);
    //save the commitments
    bytes8 z = mv.getInputBits(128);//recover the input params from MintVerifier
    zs[zCount++] = z; //add the token
    require(uint(mv.getInputBits(0))==amount); //check we've been correctly paid
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  /**
  The transfer function transfers a commitment (z-token) to a new owner
  */
  function transfer() public {
    //verification contract
    bool result = sv.verifyTx(
      proof.a,
      proof.a_p,
      proof.b,
      proof.b_p,
      proof.c,
      proof.c_p,
      proof.h,
      proof.k);
    require(result); //the proof must verify. The spice must flow.

    bytes8 nc = sv.getInputBits(0);
    bytes8 nd = sv.getInputBits(64);
    bytes8 ze = sv.getInputBits(192);
    bytes8 zf = sv.getInputBits(256);
    for (uint i=0; i<nCount; i++) { //check this is an unspent coin
      require(ns[i]!=nc && ns[i]!=nd);
    }
    ns[nCount++] = nc; //remember we spent it
    ns[nCount++] = nd; //remember we spent it
    zs[zCount++] = ze; //add Bob's token to the list of tokens
    zs[zCount++] = zf; //add Alice's token to the list of tokens
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  function burn(address payTo, bytes32 tId) payable public {
    //first, verify the proof
    bool result = mv.verifyTx(
      proof.a,
      proof.a_p,
      proof.b,
      proof.b_p,
      proof.c,
      proof.c_p,
      proof.h,
      proof.k);

    require(result); //the proof must check out ok
    //transfer OPS from this contract to the nominated address
    bytes8 C = mv.getInputBits(0);//recover the coin value
    ops.enableTransaction (tId,address(this),payTo,1,uint(C),true,false);
    ops.transferById(tId);
    bytes8 Nc = mv.getInputBits(64); //recover the nullifier
    ns[nCount++] = Nc; //add the nullifier to the list of nullifiers
    bytes8 root = merkle(0,0); //work out the Merkle root as it's now different
    currentRootIndex = roots.push(root)-1; //and save it to the list
  }

  /**
  This function is only needed because mint and transfer otherwise use too many
  local variables for the limited stack space. Rather than pass a proof as
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
    //this is long because I can't think of another way to equate memory with storage
    proof.a[0] = a[0];
    proof.a[1] = a[1];
    proof.a_p[0] = a_p[0];
    proof.a_p[1] = a_p[1];
    proof.b[0][0] = b[0][0];
    proof.b[0][1] = b[0][1];
    proof.b[1][0] = b[1][0];
    proof.b[1][1] = b[1][1];
    proof.b_p[0] = b_p[0];
    proof.b_p[1] = b_p[1];
    proof.c[0] = c[0];
    proof.c[1] = c[1];
    proof.c_p[0] = c_p[0];
    proof.c_p[1] = c_p[1];
    proof.h[0] = h[0];
    proof.h[1] = h[1];
    proof.k[0] = k[0];
    proof.k[1] = k[1];
  }

  function getTokens() public view returns(bytes8[merkleWidth], uint root) {
    //need the coins to compute a proof and also an index to look up the current
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
    //calculating the whole tree fro scratch each time.  Need to look at storing
    //intermediate values and seeing if that will make it cheaper.
    if (r==lastRow) {
      return zs[t];
    } else {
      //bytes32 parentLong = sha256(bytes16(merkle(r+1,2*t)) | (bytes16(merkle(r+1,2*t+1))>>64))<<192;
      //bytes8 parent = bytes8(parentLong);
      return bytes8(sha256(merkle(r+1,2*t)^merkle(r+1,2*t+1))<<192);
    }
  }
}
