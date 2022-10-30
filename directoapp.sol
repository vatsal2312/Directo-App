// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
import  "./console.sol";

contract directoapp is Ownable { 

    using Counters for Counters.Counter;
    Counters.Counter private projectIds;
    Counters.Counter private completeProject; 
    Counters.Counter private reviewId;     
   
    address public wallet;
    uint256 shoper = 1200;//10%
    uint256 freelancer = 1000;//12%
    mapping(uint256=>perposal) public approve;
    mapping(address=>Review) public review;

    IERC20 token;
    
    
    uint256 acceptlimit = 1000 ;//offersend seconds
    uint256 reviewlimit = 1000; //changingRequest
    uint256 withdrawLimit = 1000;//offer complete time

    function Acceptlimit (uint256 time)public onlyOwner{
        acceptlimit=time;
    }
   
    function Reviewlimit (uint256 time)public onlyOwner{
        reviewlimit=time;
    }

    function WithdrawLimit (uint256 time)public onlyOwner{
        withdrawLimit=time;
    }
   
   
   
   
   
   
    constructor(address _wallet, address _token ) { 
    wallet= _wallet;
    token = IERC20(_token);
    
    }
    
    struct perposal{
    uint256 id;
    bool accept;
    bool deny;
    bool time;
    uint256 amount;
    address sender;
    address reciver;
    uint256 timeStart; 
    uint256 timeEnd;   
    uint256 offerSend;
    uint256 offerEnd;
    }

    struct Review{
    uint256 ProjectId;
    uint256 reviewId;
    uint256 reviewStart;
    uint256 reviewEnd;
    bool amontFreze;  

    }
  
    
    function shoperPercentageAmount(uint256 amount) private view returns (uint256) {
        return (amount / 10000) * shoper;
    }

    function freelancerPercentageAmount(uint256 amount) private view returns (uint256) {
        return (amount / 10000) * freelancer;
    }
  
   function setTokenAddress(address _wallet) public onlyOwner {
    wallet=_wallet;
    }

    function setwalletAddress(address _addr) public onlyOwner {
    token = IERC20(_addr);
    }
    
    
    function sendoffer(address _addr, uint256 _amount) external{
        
        projectIds.increment();
        uint256 pIds = projectIds.current();
    require(_amount>0,"amount must b graterthan 0");
      
    // uint256 tenPersontage = shoperPercentageAmount(_amount);
    // uint256 reminAmount = _amount-tenPersontage;
    // token.transferFrom(msg.sender,wallet, tenPersontage);
     token.transferFrom(msg.sender,address(this),_amount);
    approve[pIds]=perposal(pIds,false,false,false,_amount,msg.sender,_addr,0,0,block.timestamp,block.timestamp+acceptlimit);
    }

    function offerComplete(address _addr, uint256 projectId)external{
    require(approve[projectId].sender == msg.sender,"you dont assign this offer");
    require(approve[projectId].reciver == _addr,"you enter address is wrong");
    approve[projectId].time = true;
    approve[projectId].timeStart = block.timestamp;
    approve[projectId].timeEnd = block.timestamp + withdrawLimit;//mints
    }

    
    function acceptOffer(uint256 projectId)external{  
    require(approve[projectId].reciver == msg.sender,"dont have offer");
    require(approve[projectId].accept == false,"you already accept this offer");
    require(approve[projectId].deny == false,"you deny this offer");
    require(approve[projectId].offerEnd>block.timestamp,"offer time ended, you lose the offer");
    
   // perposal storage project = approve[projectId];
    
    uint256 tenPersontage = shoperPercentageAmount(approve[projectId].amount);
    // uint256 reminAmount = project.amount-tenPersontage;
    //token.transferFrom(project.sender,wallet, tenPersontage);
    token.transfer(wallet, tenPersontage);
    approve[projectId].amount=approve[projectId].amount-tenPersontage;
    approve[projectId].accept=true;
    }

    
    function refuseToOffer(uint256 projectId) public returns(string memory) {
    if(approve[projectId].reciver == msg.sender){
    require(approve[projectId].deny == false,"you already approve");
    approve[projectId].deny=true;
    // uint256 Transferamount = approve[projectId].amount;
    token.transfer(approve[projectId].sender, approve[projectId].amount);
    approve[projectId].amount = 0;
    return "sucessfull";
    }
    else {
        return "id not found";
    }
        
    }

   
    function withdraw(address _addr, uint256 projectId) external {
   
    if (approve[projectId].accept == false && approve[projectId].deny == false){
    require(approve[projectId].reciver == _addr,"you enter address is wrong");
    require(review[_addr].amontFreze == false,"please respone review request");
    require(approve[projectId].offerEnd<block.timestamp,"please wait 48 hours");
    uint256 Transferamount = approve[projectId].amount;
    token.transfer(msg.sender, Transferamount);
    approve[projectId].amount = 0;

    }

    else if (approve[projectId].accept == true && approve[projectId].deny == false){
    require(review[msg.sender].amontFreze == false,"please respone review request");
    require(approve[projectId].reciver == msg.sender,"you are not the owner");
    require(approve[projectId].time == true,"time is not started");
    require(approve[projectId].timeEnd<=block.timestamp,"wait for withdraw time");
    uint256 twelve = freelancerPercentageAmount(approve[projectId].amount);
    uint256 Transferamount = approve[projectId].amount - twelve;
    token.transfer(msg.sender, Transferamount);
    token.transfer(wallet, twelve);
    approve[projectId].amount = 0;

    }
    
    }

    

    function getIdAddress(uint256 projectId) public view returns( perposal[] memory ){ 
        perposal[] memory items = new perposal[](projectId); 
        perposal storage currentItem = approve[projectId]; 
        items[0] = currentItem; 
    return items; 
    }


    function changeRequest(address addr, uint256 projectId) public {
    require(approve[projectId].sender == msg.sender,"you are not the shoper");
    require(approve[projectId].time == true,"time is not started"); 
    require(approve[projectId].timeEnd > block.timestamp,"time is completed");
    if(approve[projectId].reciver == addr){
    reviewId.increment();
    uint256 rId = reviewId.current();
    uint256 endTime=block.timestamp + reviewlimit; //48 hours
    review[addr]=Review(projectId,rId,block.timestamp,endTime,true);
    }
    }

    function reponse (uint256 projectId)public{
        require(approve[projectId].reciver == msg.sender,"you are not a reciver");
        if(review[msg.sender].reviewEnd < block.timestamp){
            review[msg.sender].amontFreze = false; 
        }

    }


    function fetchIncomingOffer(address acount) public view returns (perposal[] memory) { 
        uint totalItemCount = projectIds.current(); 
        uint itemCount = 0; 
        uint currentIndex = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve[i + 1].reciver == acount) { 
        itemCount += 1; 
        } 
        } 
  
        perposal[] memory items = new perposal[](itemCount); 
        for (uint i = 0; i < totalItemCount; i++) { 
         if (approve[i + 1].reciver ==acount) { 
         uint currentId = i + 1; 
        perposal storage currentItem = approve[currentId]; 
        items[currentIndex] = currentItem; 
        currentIndex += 1; 
        } 
        } 
    return items; 
         } 


        function fetchOutgoingOffer(address acount) public view returns (perposal[] memory) { 
        uint totalItemCount = projectIds.current(); 
        uint itemCount = 0; 
        uint currentIndex = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve[i + 1].sender == acount) { 
        itemCount += 1; 
        } 
        } 
  
        perposal[] memory items = new perposal[](itemCount); 
        for (uint i = 0; i < totalItemCount; i++) { 
         if (approve[i + 1].sender ==acount) { 
         uint currentId = i + 1; 
        perposal storage currentItem = approve[currentId]; 
        items[currentIndex] = currentItem; 
        currentIndex += 1; 


        } 
        } 
    return items; 
         } 


    function getAllOffers(address account) public view returns(uint256){  
        uint totalItemCount = projectIds.current(); 
        uint itemCount = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve[i + 1].reciver == account) { 
        itemCount += 1; 
        } 
        } 
            return itemCount;
        }

}
