pragma solidity ^0.5.0;

import "./ownable.sol";
import "./dccoinact.sol";

contract dccoin is Ownable, dccoinact {

   struct Transaction {
      uint8 typeTransaction;
      uint64 timeTransaction;
      uint valueTransaction;
      bool withdrawable;
      uint info;
  }
  struct Project {
      uint idProject;
      uint valueProjectWithdraw;
      uint valueProjectDeposit;
      uint64 timeWithdrawProject;
      uint64 timeDepositProject;
      uint[] idTransactions;
      bool openProject;
      uint auxBal;
      uint[] auxBalTransactions;
  }
  
  Transaction[] public ledger;
  Project[] public inversions;
  mapping (uint => address) public idTransactionToUser;

  uint public minDeposit = 1;
  
    // //////////////////////////////////////
   // Modifiers for Validate Transactions //
  // //////////////////////////////////////
  
  modifier onlyUser(){
      require(isUser());
      _;  
  }
  

    // ////////////////////////
   // Functions Helper Code //
  // ////////////////////////
  
  function() external payable {}
  function _intDivision(uint _num, uint _den) public pure returns (uint) {
      return((_num-(_num % _den))/_den);
  }
  function _expFraction(uint _base, uint _num, uint _den, uint _exp) public pure returns (uint) {
      uint ans = _base;
      for (uint i=1; i <= _exp; i++) {
          ans = ans*_num/_den;
      }
      return ans;
  }
  function isUser() public view returns(bool) {
      uint i = 0;
      bool _isUser = false;
      while (i <= (ledger.length - 1)){
          if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true){
              _isUser = true;
              break;
          }
          i++;
      }
      return _isUser;
  }

    // ////////////////////////////
   // DCCoin Transactions Code  //
  // ////////////////////////////
  
  function setMinDeposit(uint _minDeposit) public onlyOwner {
    minDeposit = _minDeposit;
  }
  function getMinDeposit() public view returns (uint) {
    return minDeposit;
  }
  function currentDC() public view  onlyUser returns (uint) {
      uint _currentDC = 0;
      for (uint i=0; i <= (ledger.length - 1); i++) {
          if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true) {
              if ((uint(now)-uint64(ledger[i].timeTransaction)) < 15768000) {
                  _currentDC = _currentDC + _expFraction(uint(ledger[i].valueTransaction),_intDivision(uint(now)-uint(ledger[i].timeTransaction),5256000)+1,6,1);
              } else {
                  _currentDC = _currentDC + _expFraction(uint(ledger[i].valueTransaction), 98, 100, _intDivision(uint(now)-uint(ledger[i].timeTransaction),31536000)+1);
              }
          }
      }
      return _currentDC;
  }
  function currentDeposits() public view onlyUser returns (uint) {
       uint _currentDeposits = 0;
       for (uint i=0; i <= (ledger.length - 1); i++){
           if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true) {
               _currentDeposits = _currentDeposits + ledger[i].valueTransaction;
           }
       }
       return _currentDeposits;
  }
  function depositEther() public payable {
      require(msg.value >= minDeposit);
      uint idTransaction = ledger.push(Transaction(uint8(1), uint64(now), msg.value, true, 0)) - 1;
      idTransactionToUser[idTransaction] = msg.sender;
  }
  function withdrawEther(uint valueWithdraw) public payable onlyUser {
      require(currentDC() > valueWithdraw);
      uint founds = currentDC();
          for (uint i=0; i <= (ledger.length - 1); i++){
              if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true)
              ledger[i].withdrawable = false;
              }
          msg.sender.transfer(valueWithdraw);
          uint idTransaction = ledger.push(Transaction(uint8(2), uint64(now), founds - valueWithdraw, true, 0)) - 1;
          idTransactionToUser[idTransaction] = msg.sender;
  }
  function withdrawEtherAll() public payable  onlyUser {
      require(currentDC() > 0);
      uint founds = currentDC();
      for (uint i=0; i <= (ledger.length - 1); i++){
          if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true){
              ledger[i].withdrawable = false;
          }
      }
      msg.sender.transfer(founds);
      uint idTransaction = ledger.push(Transaction(uint8(3), uint64(now), founds, false, 0)) - 1;
      idTransactionToUser[idTransaction] = msg.sender;
     
  }
  function getCountDeposits() public view returns (uint) {
      uint count = 0;
      for (uint i=0; i <= (ledger.length - 1); i++){
          if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true){
              count++;
          }
      }
      return count;
  }
  function getKTransactionUser(uint k) public view returns (uint8, uint, uint, bool, uint) {
      uint count = 0;
      uint8 _typeTransaction;
      uint _timeTransaction;
      uint _valueTransaction;
      bool _withdrawable;
      uint _info;
      for (uint i=0; i <= (ledger.length - 1); i++){
          if (idTransactionToUser[i] == msg.sender && ledger[i].withdrawable == true && k <= getCountDeposits()){
              if (count == k){
                  _typeTransaction = ledger[i].typeTransaction;
                  _timeTransaction = ledger[i].timeTransaction;
                  _valueTransaction = ledger[i].valueTransaction;
                  _withdrawable = ledger[i].withdrawable;
                  _info = ledger[i].info;
                  break;
              }
              count++;
          }
      }
      return (_typeTransaction, _timeTransaction, _valueTransaction, _withdrawable, _info);
  }
  
    // //////////////////
   // Inversions Code //
  // //////////////////
  
  function getBalance() public view onlyOwner returns (uint) {
      return(address(this).balance);
  }
  function getBalanceWithdrawable() public view onlyOwner returns(uint) {
      uint _balanceWithdrawable = 0;
      for (uint i=0; i <= (ledger.length - 1); i++) {
          if (ledger[i].withdrawable == true) {
            _balanceWithdrawable = _balanceWithdrawable + _expFraction(uint(ledger[i].valueTransaction), 98, 100, _intDivision(uint(now)-uint(ledger[i].timeTransaction),31536000)+1);
          }
      }
      return _balanceWithdrawable;
  }
  function getCountLedger() public view onlyOwner returns (uint) {
      return ledger.length;
  }
  function getCountLedgerWithdrawable() public view onlyOwner returns (uint) {
      uint count = 0;
      if (ledger.length > 0){
           for (uint i = 0; i <= (ledger.length - 1); i++) {
               if (ledger[i].withdrawable == true) {
                   count++;
                }
            }
      }
      return count;
  }
  function getKTransactionLedger(uint k) public view onlyOwner returns (uint8, uint, uint, bool, uint) {
      uint8 _typeTransaction;
      uint _timeTransaction;
      uint _valueTransaction;
      bool _withdrawable;
      uint _info;
      if (ledger.length >= k){
          _typeTransaction = ledger[k].typeTransaction;
          _timeTransaction = ledger[k].timeTransaction;
          _valueTransaction = ledger[k].valueTransaction;
          _withdrawable = ledger[k].withdrawable;
          _info = ledger[k].info;

      }
      return (_typeTransaction, _timeTransaction, _valueTransaction, _withdrawable, _info);
  }
  function getKTransactionLedgerWitdrawable(uint k) public view onlyOwner returns (uint8, uint, uint, bool, uint) {
      uint count = 0;
      uint8 _typeTransaction;
      uint _timeTransaction;
      uint _valueTransaction;
      bool _withdrawable;
      uint _info;
      for (uint i=0; i <= (ledger.length - 1); i++){
          if (ledger[i].withdrawable == true && k <= getCountLedgerWithdrawable()){
              if (count == k){
                  _typeTransaction = ledger[i].typeTransaction;
                  _timeTransaction = ledger[i].timeTransaction;
                  _valueTransaction = ledger[i].valueTransaction;
                  _withdrawable = ledger[i].withdrawable;
                  _info = ledger[i].info;
                  break;
              }
              count++;
          }
      }
      return (_typeTransaction, _timeTransaction, _valueTransaction, _withdrawable, _info); 
  }
  function withdrawProject(uint valueProject) public payable onlyOwner returns (uint) {
      require(getBalance() > valueProject);
      uint invCount = inversions.length;
      uint _idaux;
      uint preWithdraw;
      uint[] memory listIDTransactions = new uint[](0);
      uint[] memory listBalTransactions = new uint[](0);
      uint n = ledger.length;
      uint getBalWith = getBalanceWithdrawable();
      msg.sender.transfer(valueProject);
      inversions.push(Project(invCount, valueProject, 0, uint64(now), 0, listIDTransactions, true, getBalWith, listBalTransactions));
      for(uint i=0; i<n; i++) {
          if (ledger[i].withdrawable == true){
            if(ledger[i].typeTransaction == 4 || ledger[i].typeTransaction == 5) {
                    preWithdraw = ledger[i].info;
                } else {
                    preWithdraw = ledger[i].valueTransaction;
                }
                    _idaux = ledger.push(Transaction(uint8(4), ledger[i].timeTransaction, ledger[i].valueTransaction-(_intDivision((ledger[i].valueTransaction)*(valueProject),getBalWith)), true, preWithdraw)) - 1;
                    idTransactionToUser[_idaux] = idTransactionToUser[i];
                    ledger[i].withdrawable = false;
                    inversions[invCount].idTransactions.push(_idaux);
                    inversions[invCount].auxBalTransactions.push(_expFraction(uint(ledger[i].valueTransaction), 98, 100, _intDivision(uint(now)-uint(ledger[i].timeTransaction),31536000)+1));
           }
        }
      return (invCount);
  }
  function depositProject(uint k) public payable onlyOwner {
      require(k < inversions.length && inversions[k].openProject == true);
      uint _idTransaction;
      uint j;
      uint valueWithdrawProject = inversions[k].valueProjectWithdraw;
      uint n = inversions[k].idTransactions.length; 
      uint valueSuitable = msg.value;
      inversions[k].openProject = false;
      inversions[k].timeDepositProject = uint64(now);
      inversions[k].valueProjectDeposit = msg.value;
      uint auxBalWith = inversions[k].auxBal;
      if ((2*valueWithdrawProject) < valueSuitable){
          valueSuitable = _intDivision(8*msg.value,10);
      }
      for (uint i=0; i < n; i++) {
          j = inversions[k].idTransactions[i];
          _idTransaction = ledger.push(Transaction(uint8(5), ledger[j].timeTransaction, _intDivision(valueSuitable*(inversions[k].auxBalTransactions[i]),auxBalWith) + ledger[j].valueTransaction , true, ledger[j].info)) - 1;
          idTransactionToUser[_idTransaction] = idTransactionToUser[j];
          ledger[j].withdrawable = false;
      }        
  }
  function withdrawFees() public payable onlyOwner {
      uint _balanceWithdrawable = 0;
      for (uint i=0; i <= (ledger.length - 1); i++) {
          if (ledger[i].withdrawable == true) {
            _balanceWithdrawable = _balanceWithdrawable + _expFraction(uint(ledger[i].valueTransaction), 98, 100, _intDivision(uint(now)-uint(ledger[i].timeTransaction),31536000)+1);
            }
      }
      if (getBalance()-(_balanceWithdrawable) > 0){
          msg.sender.transfer(getBalance()-(_balanceWithdrawable));
      }
      
  }
  function getCountProjects() public view returns(uint){
      return inversions.length;
  }
  function getKProject(uint k) public view returns (uint, uint, uint, uint64, uint64) {
      return (inversions[k].idProject, inversions[k].valueProjectWithdraw, inversions[k].valueProjectDeposit, inversions[k].timeWithdrawProject, inversions[k].timeDepositProject);
  }
}

