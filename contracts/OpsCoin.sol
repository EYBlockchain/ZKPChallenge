pragma solidity ^0.4.11;

import "./ERC20Interface.sol/";

/**
 * The OpsCoin is a kind of fiat currency which is mapped to each location address.
 * This contract provides functions to buy Coins,
 * withdraw, enable transaction fund and transfer fund
 */

contract OpsCoin is ERC20Interface {

    string public constant symbol = "OPS";
    string public constant name = "Ops Coin";

    // Owner of this contract
    address public owner;

    // transaction struct
    struct Transaction {
        address from;
        address to;
        uint256 lockedTill;
        uint256 amount;
        bool enabled;
        bool withdrawn;
        bool isValid;
        uint256 enableIndex;
        uint256 withdrawIndex;
    }

    // creates mapping b/w asset transfer hash and transaction
    mapping(bytes32 => Transaction) private transactions;

    // Creates a mapping b/w location address and opscoin
    mapping(address => uint256) private balances;

    // creates a mapping b/w sender location address and array of asset transfer hash
    mapping(address => bytes32[]) private withdrawTransactionList;

    // creates a mapping b/w receiver location address and array of asset transfer hash
    mapping(address => bytes32[]) private enableTransactionList;

    // creates a mapping b/w sender location address and array of asset transfer hash(withdrawn)
    mapping(address => bytes32[]) private withdrawTransactionHistory;

    // creates a mapping b/w receiver location address and array of asset transfer hash(withdrawn)
    mapping(address => bytes32[]) private enableTransactionHistory;

    //only owner  modifier
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }

    /**
     * Constructor function invoked during contract deployment
     */
    constructor () public {
        owner = msg.sender;
    }

    /**
     * Buy OpsCoin
     * @param  _amount - no of coin
     * @param _location - location address
     */
    function buyOpsCoin (uint256 _amount, address _location) public returns (bool success) {
        require(_amount > 0);
        balances[_location] += _amount;
        return true;
    }

    /**
     * convert OpsCoin to real money
     * @param _location - location address
     */
    function convertOpsCoin (address _location) public returns (bool success) {
        require(balances[_location] > 0);
        balances[owner] += balances[_location];
        balances[_location] = 0;
        return true;
    }

    /**
     * Get the coin the balance of a particular account
     * @param  _location  - location address
     */
    function balanceOf(address _location) public constant returns (uint256 balance) {
        return balances[_location];
    }

    /**
     * Transfer the opscoin from one location to another. This will basically set the withdrawn flag to true and
     * move the transfer hash from active to history list
     * @param  _transactionId - transaction Id of the transaction
     */
    function transferById (bytes32 _transactionId) public returns (bool) {
        Transaction storage currentTransaction = transactions[_transactionId];
        require(isValidTransaction(_transactionId) == true);
        require(balances[currentTransaction.from] >= currentTransaction.amount);
        //assert(msg.sender == transactions[_transactionId].from);
        //require(currentTransaction.lockedTill > now);
        require(currentTransaction.withdrawn != true);
        balances[currentTransaction.to] += currentTransaction.amount;
        balances[currentTransaction.from] -= currentTransaction.amount;
        currentTransaction.withdrawn = true;
        uint256 enableIndex = currentTransaction.enableIndex;
        uint256 withdrawIndex = currentTransaction.withdrawIndex;
        enableTransactionList[currentTransaction.from][enableIndex] = enableTransactionList[currentTransaction.from][enableTransactionList[currentTransaction.from].length - 1];
        transactions[enableTransactionList[currentTransaction.from][enableIndex]].enableIndex = enableIndex;
        withdrawTransactionList[currentTransaction.to][withdrawIndex] = withdrawTransactionList[currentTransaction.to][withdrawTransactionList[currentTransaction.to].length - 1];
        transactions[withdrawTransactionList[currentTransaction.to][withdrawIndex]].withdrawIndex = withdrawIndex;
        enableTransactionList[currentTransaction.from].length = enableTransactionList[currentTransaction.from].length - 1;
        withdrawTransactionList[currentTransaction.to].length = withdrawTransactionList[currentTransaction.to].length - 1;
        enableTransactionHistory[currentTransaction.from].push(_transactionId);
        withdrawTransactionHistory[currentTransaction.to].push(_transactionId);
      //  emit Transfer(currentTransaction.to, currentTransaction.from, currentTransaction.amount);
        return true;
    }

    /**
     * Initiate a transaction b/w sender and reciver location once a asset has been transfered
     * @param  _transactionId - transaction hash  of the asset transfer
     * @param  _from - asset receiver address
     * @param  _to - asset sender address
     * @param  _lockedTill - lock period
     * @param  _amount - value of asset
     * @param  _enabled - whether transaction is enabled ? default is true
     * @param  _withdrawn - whether amount is withdrawn ? default is false
     */
    function enableTransaction (
        bytes32 _transactionId,
        address _from,
        address _to,
        uint256 _lockedTill,
        uint256 _amount,
        bool _enabled,
        bool _withdrawn) public returns (bool success) {
        require(isValidTransaction(_transactionId) != true);
        transactions[_transactionId] = Transaction(_from, _to, _lockedTill, _amount, _enabled, _withdrawn, true, enableTransactionList[_from].length, withdrawTransactionList[_to].length);
        withdrawTransactionList[_to].push(_transactionId);
        enableTransactionList[_from].push(_transactionId);
    //    emit EnableTransfer(transactions[_transactionId].from, transactions[_transactionId].to, transactions[_transactionId].lockedTill, transactions[_transactionId].amount, transactions[_transactionId].enabled, transactions[_transactionId].withdrawn);
        return true;
    }

    /**
    * Returns an array of transfer hash mapped againt the asset sender. Mapping is created b/w this hash and transaction
    * @param _location - location address
     */
    function getWithdrawTransactionList(address _location) public view returns (bytes32[]) {
        return withdrawTransactionList[_location];
    }

    /**
    * Returns an array of transfer hash mapped againt the asset receiver. Mapping is created b/w this hash and transaction
    * @param _location - location address
     */
    function getEnableTransactionList(address _location) public view returns (bytes32[]) {
        return enableTransactionList[_location];
    }

    /**
    * Returns an array of transfer hash mapped againt the asset sender which is already withdrawn. Mapping is created b/w this hash and transaction
    * @param _location - location address
     */
    function getWithdrawTransactionHistory(address _location) public view returns (bytes32[]) {
        return withdrawTransactionHistory[_location];
    }

    /**
    * Returns an array of transfer hash mapped againt the asset receiver which is already withdrawn. Mapping is created b/w this hash and transaction
    * @param _location - location address
     */
    function getEnableTransactionHistory(address _location) public view returns (bytes32[]) {
        return enableTransactionHistory[_location];
    }

    /**
     * Toggle a transaction
     * @param _transactionId - transaction Id of the transaction
     */
    function toggleTransaction (bytes32 _transactionId) public returns(bool success) {
        assert(isValidTransaction(_transactionId) == true);
        transactions[_transactionId].enabled = !transactions[_transactionId].enabled;
    //    emit ToggleTransfer(_transactionId);
        return true;
    }

    /**
     * Returns details of the transaction
     * @param  _transactionId - transaction Id of the transaction
     */
    function getTransaction (bytes32 _transactionId) public view returns (bytes32, address, address, uint256, uint256, bool, bool) {
        assert(isValidTransaction(_transactionId) == true);
        return (_transactionId,
                transactions[_transactionId].from,
                transactions[_transactionId].to,
                transactions[_transactionId].lockedTill,
                transactions[_transactionId].amount,
                transactions[_transactionId].enabled,
                transactions[_transactionId].withdrawn);
    }

    /**
     * Check if transaction is valid
     * @param  _transactionId - transaction Id of the transaction
     */
    function isValidTransaction(bytes32 _transactionId) private view returns (bool success) {
        return transactions[_transactionId].isValid;
    }

}
