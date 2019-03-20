pragma solidity ^0.5.0;

import "./ownable.sol";


contract dccoinact is Ownable{
    
    struct Market {
        string nameMarket;
        uint64 startTimeMarket;
        uint64 endTimeMarket;
        string[] solutionsMarket;
        uint[] solutionsMarketValue;
        uint finalSolution;
        bool payoutMarket;
    }
    struct Bet {
        uint idMarket;
        uint solutionBet;
        uint valueBet;
        bool payoutBet;
    }
    struct Dispute {
        uint idMarket;
        uint solution;
        bool payoutDispute;
    }
    struct PA {
        uint idPA;
        address addressPA;
        uint valuePA;
        uint64 timeExpirationPA;
    }
    struct ProjectSug {
        uint idProjectSug;
        address creatorProject;
        string nameProject;
        uint value;
        uint64 timeProject;
        string infoProject;
    }
    Market[] public MarketLedger;
    Bet[] public BetLedger;
    Dispute[] public DisputeLedger;
    ProjectSug[] public ProjectSugLedger;
    PA[] public PALedger;
    mapping (address => uint) Tokens;
    mapping (uint => address) marketToCreator;
    mapping (uint => address) betToUser;
    mapping (uint => address) disputeToUser;
    
    

    
      // ////////////////////////
     // Functions Helper Code //
    // ////////////////////////

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
    
    
      // /////////////////////
     //  Creation  Ledgers //
    // /////////////////////
    
    
    function creationUser() public {
        require(Tokens[msg.sender]==0);
        Tokens[msg.sender] = 10000;
        
    }
    function creationMarket(string memory _name, uint64 _endTime) public {
        require(bytes(_name).length > 0 && uint64(now) < _endTime && Tokens[msg.sender] > 0);
        string[] memory list1 = new string[](0);
        uint[] memory list2 = new uint[](0);
        uint idMarket = MarketLedger.push(Market(_name,uint64(now), _endTime, list1, list2, 0, false)) - 1;
        marketToCreator[idMarket] = msg.sender;
    }
    function attachMarketSolution(string memory _solution, uint _idMarket) public {
        require(bytes(_solution).length > 0 && MarketLedger[_idMarket].endTimeMarket > uint64(now)  && Tokens[msg.sender] > 0);
        MarketLedger[_idMarket].solutionsMarket.push(_solution);
        MarketLedger[_idMarket].solutionsMarketValue.push(0);
    }
    function createBet(uint _value, uint _idMarket, uint _idSolution) public {
        require(MarketLedger.length > _idMarket && MarketLedger[_idMarket].solutionsMarket.length> _idSolution && MarketLedger[_idMarket].endTimeMarket > uint64(now) && Tokens[msg.sender] > _value);
        Tokens[msg.sender] = Tokens[msg.sender] - _value;
        MarketLedger[_idMarket].solutionsMarketValue[_idSolution] = MarketLedger[_idMarket].solutionsMarketValue[_idSolution] + _value;
        uint idBet = BetLedger.push(Bet(_idMarket,_idSolution, _value, false)) - 1;
        betToUser[idBet] = msg.sender;
    }
    function createDispute(uint _idMarket, uint _solution) public {
        require(Tokens[msg.sender] > 100 && (uint64(now)-MarketLedger[_idMarket].endTimeMarket) < 604800 && disputedKMarketByMe(_idMarket)==false);
        Tokens[msg.sender] = Tokens[msg.sender] - 100;
        uint idDispute = DisputeLedger.push(Dispute(_idMarket, _solution, false)) - 1;
        disputeToUser[idDispute] = msg.sender;
    }
    
    
      // //////////////////
     // PayOut Function //
    // //////////////////
    
    function disputedKMarketByMe(uint k) public view returns(bool){
        bool x = false;
        for(uint i=0; i < DisputeLedger.length; i++) {
            if(disputeToUser[i]==msg.sender && DisputeLedger[i].idMarket == k){
                x = true;
                break;
            }
        }
        return x;
    }
    function marketDisputed(uint _idMarket) public view returns (bool) {
        bool x = false;
        uint i = 0;
        while(x == false && i < DisputeLedger.length){
            if (DisputeLedger[i].idMarket == _idMarket) {
                x = true;
            }
            i++;
        }
        return x;
    }
    function marketDisputedSolvedTrue(uint _idMarket) public view returns (bool) {
        bool x = false;
        uint[] memory list = new uint[](MarketLedger[_idMarket].solutionsMarket.length);
        for (uint i = 0; i < DisputeLedger.length; i++) {
            if (DisputeLedger[i].idMarket == _idMarket){
                list[DisputeLedger[i].solution] = list[DisputeLedger[i].solution] + 1;
            }
        }
        uint vartest;
        for(uint j = 0; j < list.length; j++){
            if(list[j] > vartest){
                vartest = list[j];
                x = true;
            } else if (list[j] == vartest) {
                x = false;
            }
        }
        return x;
    }
    function marketSolutionFinal(uint _idMarket) public view returns (uint) {
        uint[] memory list = new uint[](MarketLedger[_idMarket].solutionsMarket.length);
        for (uint i = 0; i < DisputeLedger.length; i++) {
            if (DisputeLedger[i].idMarket == _idMarket){
                list[DisputeLedger[i].solution] = list[DisputeLedger[i].solution] + 1;
            }
        }
        uint vartest;
        uint x = 0;
        for(uint j = 0; j < list.length; j++){
            if(list[j] > vartest){
                vartest = list[j];
                x = j;
            }
        }
        return x;
    }
    function getValueBetsMarket(uint _idMarket) public view returns (uint) {
        uint x;
        for (uint i = 0; i < BetLedger.length; i++){
            if (BetLedger[i].idMarket == _idMarket) {
                x = x + BetLedger[i].valueBet;
            }
        }
        return x;
    }
    function getValueBetsWinnersMarket(uint _idMarket) public view returns (uint) {
        uint x;
        uint _marketSolution = marketSolutionFinal(_idMarket);
        for (uint i = 0; i < BetLedger.length; i++){
            if (BetLedger[i].idMarket == _idMarket  &&  _marketSolution == BetLedger[i].solutionBet) {
                x = x + BetLedger[i].valueBet;
            }
        }
        return x;
    }
    function getValueDisputesMarket(uint _idMarket) public view returns (uint) {
        uint x;
        for (uint i = 0; i <DisputeLedger.length; i++){
            if (DisputeLedger[i].idMarket == _idMarket) {
                x = x + 1;
            }
        }
        return x;
    }
    function getValueDisputesWinnersMarket(uint _idMarket) public view returns (uint) {
        uint x;
        uint _marketSolution = marketSolutionFinal(_idMarket);
        for (uint i = 0; i < DisputeLedger.length; i++){
            if (DisputeLedger[i].idMarket == _idMarket  && _marketSolution == BetLedger[i].solutionBet) {
                x = x + 1;
            }
        }
        return x;
    }
    
    function solveMarket(uint _idMarket) public  {
    require((MarketLedger[_idMarket].endTimeMarket + uint64(604800)) < uint64(now) && MarketLedger[_idMarket].payoutMarket == false && marketDisputed(_idMarket));
    if(marketDisputedSolvedTrue(_idMarket)) {
           uint _marketSolution = marketSolutionFinal(_idMarket);
           MarketLedger[_idMarket].finalSolution = _marketSolution;
           uint awardBet = getValueBetsMarket(_idMarket);
           uint awardBetDealer = getValueBetsWinnersMarket(_idMarket);
           for(uint i = 0; i < BetLedger.length ; i++) {
               if(BetLedger[i].solutionBet == _marketSolution && BetLedger[i].idMarket == _idMarket) {
                   Tokens[betToUser[i]] = Tokens[betToUser[i]] + _intDivision(awardBet*BetLedger[i].valueBet,awardBetDealer);
               }
               BetLedger[i].payoutBet = true;
           }
           for (uint j = 0; j < DisputeLedger.length ; j++) {
               if(DisputeLedger[j].solution == _marketSolution && DisputeLedger[j].idMarket == _idMarket) {
                  Tokens[disputeToUser[j]] = Tokens[disputeToUser[j]] + 150;
               }
               DisputeLedger[j].payoutDispute = true;
           }
           
       } else {
            for(uint i = 0; i < BetLedger.length ; i++) {
                if(BetLedger[i].idMarket == _idMarket){
                    Tokens[betToUser[i]] = Tokens[betToUser[i]] + BetLedger[i].valueBet;
                }
                BetLedger[i].payoutBet = true;
            }
            
            for(uint j = 0; j < DisputeLedger.length ; j++) {
                if(DisputeLedger[j].idMarket == _idMarket) {
                    Tokens[disputeToUser[j]] = Tokens[disputeToUser[j]] + 100;
                }
                DisputeLedger[j].payoutDispute = true;
            }
       }
       MarketLedger[_idMarket].payoutMarket = true;
    }

      // /////////////// 
     // Getters User //
    // ///////////////
    
    function getTokens() public view returns (uint) {
        return Tokens[msg.sender];
    }
    function getCountMarkets() public view returns(uint) {
        return(MarketLedger.length);
    }
    function getCountMarketsSolved() public view returns(uint) {
        uint n = 0;
        for(uint i = 0; MarketLedger.length > i; i++){
            if(MarketLedger[i].payoutMarket == false){
                n++;
            }
        }
        return n;
    }
    function getCountSolutionsMarket(uint _idMarket) public view returns (uint) {
        return MarketLedger[_idMarket].solutionsMarket.length;
    
    }
    function getKMarket(uint k) public view returns (string memory, uint64, uint64, uint, bool) {
        return (MarketLedger[k].nameMarket, MarketLedger[k].startTimeMarket, MarketLedger[k].endTimeMarket, MarketLedger[k].finalSolution, MarketLedger[k].payoutMarket);
    }
    function getStateKMarket(uint k) public view returns (uint8) {
        uint8 n;
        if(uint64(now) > MarketLedger[k].endTimeMarket) {
            n = 2;
	    if (uint64(now) > MarketLedger[k].endTimeMarket + uint64(604800)) {
                n = 1;
            }
        }
        return n;
    }
    function getKMarketNSolution(uint k, uint n) public view returns (string memory) {
        return MarketLedger[k].solutionsMarket[n];
    }
    function getCountMyBets() public view returns (uint) {
        uint x;
        for (uint i = 0; i < BetLedger.length ; i++) {
            if (msg.sender == betToUser[i]){
                x++;
            }
        }
        return x;
    }
    function getCountMyDisputs() public view returns (uint) {
        uint x;
        for (uint i = 0; i < DisputeLedger.length ; i++) {
            if (msg.sender == disputeToUser[i]){
                x++;
            }
        }
        return x;
    }
    function getMyKBet(uint k) public view returns (uint, uint, uint, bool) {
        bool x = true;
        uint i = 0;
        uint j = 0;
        while (x){
            if(betToUser[i] == msg.sender){
                if(j==k){
                    x = false;
                } else {
                    j++;
                }
            }
            i++;
        }
        return (BetLedger[i-1].idMarket, BetLedger[i-1].solutionBet ,BetLedger[i-1].valueBet ,BetLedger[i-1].payoutBet);
    }
    function getMyKDispute(uint k) public view returns (uint, uint, bool) {
        bool x = true;
        uint i;
        uint j;
        while (x){
            if(disputeToUser[i] == msg.sender){
                if(j==k){
                    x = false;
                } else {
                    j++;
                }
            }
            i++;
        }
        return (DisputeLedger[i-1].idMarket, DisputeLedger[i-1].solution ,DisputeLedger[i-1].payoutDispute);
    }
    
      // ///////////
     // Actuator //
    // ///////////
  
    function createPA(address _addressPA, uint _value, uint64 _expirationDate) public onlyOwner {
        uint _idPA = PALedger.length;
        PALedger.push(PA(_idPA,_addressPA,_value,_expirationDate)) - 1;
    }
    function getTokensAddress(address _idAddress) public view returns(uint) {
        return Tokens[_idAddress];
    }
    function createProjectSug(uint _idPA, string memory _name ,uint _value, string memory _info) public {
        require(PALedger[_idPA].addressPA == msg.sender  && PALedger[_idPA].timeExpirationPA > uint64(now) && PALedger[_idPA].valuePA >= _value);
        uint _idProjSug = ProjectSugLedger.length;
        PALedger[_idPA].valuePA = PALedger[_idPA].valuePA - _value; 
        ProjectSugLedger.push(ProjectSug(_idProjSug, msg.sender, _name, _value, uint64(now), _info));
        
    }
    function getCountPA() public view returns (uint) {
        return PALedger.length;
    }
    function getKPA(uint k) public view returns (uint, address, uint, uint64) {
        return(PALedger[k].idPA, PALedger[k].addressPA, PALedger[k].valuePA, PALedger[k].timeExpirationPA);
    }
    function getCountMyPA() public view returns (uint) {
        uint n = 0;
        for (uint i = 0; PALedger.length > i; i++) {
            if(PALedger[i].addressPA == msg.sender) {
                n++;
            }
        }
        return n;
    }
    function getMyKPA(uint k) public view returns(uint, uint, uint64) {
        uint i = 0;
        uint j = 0;
        uint ret1;
        uint ret2;
        uint64 ret3;
        bool x = true;
        while (x) {
            if(PALedger[i].addressPA == msg.sender) {
                if(j == k){
                    ret1 = PALedger[i].idPA;
                    ret2 = PALedger[i].valuePA;
                    ret3 = PALedger[i].timeExpirationPA;
                    x = false;
                }
                j++;
            }
            i++;
        }
        return (ret1, ret2, ret3);
    }
    function getCountProjectsSug() public view returns(uint) {
        return ProjectSugLedger.length;
    }
    function getKProjectSugSummarize(uint k) public view returns (uint, address, string memory, uint, uint64, string memory) {
        return (ProjectSugLedger[k].idProjectSug ,ProjectSugLedger[k].creatorProject, ProjectSugLedger[k].nameProject, ProjectSugLedger[k].value, ProjectSugLedger[k].timeProject, ProjectSugLedger[k].infoProject);
    }
    function getCountMyProject() public view returns (uint) {
        uint n = 0;
        for (uint i = 0; ProjectSugLedger.length < i; i++) {
            if(ProjectSugLedger[i].creatorProject == msg.sender) {
                n++;
            }
        }
        return n;
    }
    function getMyKProject(uint k) public view returns(string memory, uint64, uint) {
        uint i = 0;
        uint j = 0;
        string memory ret1;
        uint64 ret2;
        uint ret3;
        bool x = true;
        while (x) {
            if(ProjectSugLedger[i].creatorProject == msg.sender) {
                if(j == k){
                    ret1 = ProjectSugLedger[i].nameProject;
                    ret2 = ProjectSugLedger[i].timeProject;
                    ret3 = ProjectSugLedger[i].value;
                    x = false;
                }
                j++;
            }
            i++;
        }
        return (ret1, ret2,ret3);
    }
    function getKProjectSug(uint k) public view returns (address, string memory, uint) {
        return (ProjectSugLedger[k].creatorProject,ProjectSugLedger[k].nameProject,ProjectSugLedger[k].value);
    }
   

}