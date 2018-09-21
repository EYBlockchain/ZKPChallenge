pragma solidity ^0.4.11;
// ERC Token Standard #20 Interface
   // https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {

     // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

     // Send _value amount of tokens to address _to
    function transferById(bytes32 _transactionId) public returns (bool success);

    // Toggle a transaction
    function toggleTransaction(bytes32 _transactionId) public returns (bool success);

     // Enable buyer to withdraw after lock period
    function enableTransaction(bytes32 _transactionId, address _from, address _to, uint256 _lockedTill, uint256 _amount, bool _enabled, bool _withdrawn) public returns (bool success);

    // Get enabled transaction details
    function getTransaction(bytes32 _transactionId) public view returns (bytes32, address, address, uint256, uint256, bool, bool);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever enableTransaction() is called.
    event EnableTransfer(address indexed _from, address indexed _to, uint256 _lockedTill, uint256 _amount, bool _enabled, bool _withdrawn);

    // Triggered whenever toggleTransation is called.
    event ToggleTransfer(bytes32 _transactionId);
}
