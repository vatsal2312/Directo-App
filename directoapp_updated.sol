// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import  "./console.sol";

contract DirectoApp is Ownable , ReentrancyGuard { 

    using Counters for Counters.Counter;
    Counters.Counter private projectIds_;
    Counters.Counter private completeProject_; 
    Counters.Counter private reviewId_;     
   
    address public wallet_;
    uint256 public shoper_ = 1200;//10%
    uint256 public freelancer_ = 1000;//12%
    mapping(uint256=>perposal) public approve_;
    mapping(address=>Review) public review_;

    IERC20 public token_;
    
    
    uint256 public acceptLimit_ = 1000 ;//offersend seconds
    uint256 public reviewLimit_ = 1000; //changingRequest
    uint256 public withdrawLimit_ = 1000;//offer complete time

    function acceptLimit (uint256 time)public onlyOwner{
        acceptLimit_ = time;
    }
   
    function reviewLimit (uint256 time)public onlyOwner{
        reviewLimit_ =time;
    }

    function _withdrawLimit (uint256 time)public onlyOwner{
        withdrawLimit_ =time;
    }
   
   
   
   
    constructor(address _wallet, address _token )  {
    require(_wallet != address(0),"invalid address");
    require(_token != address(0),"invalid address");  

    wallet_ = _wallet;
    token_ = IERC20(_token);
    
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
        return (amount * shoper_) / 10000;
    }

    function freelancerPercentageAmount(uint256 amount) private view returns (uint256) {
        return (amount * freelancer_) / 10000;
    }
  
   function setTokenAddress(address _wallet) public onlyOwner {
    wallet_ =_wallet;
    }

    function setwalletAddress(address _addr) public onlyOwner {
    token_ = IERC20(_addr);
    }
    
    
    function sendoffer(address _addr, uint256 _amount) external{
        
        projectIds_.increment();
        uint256 pIds = projectIds_.current();
       require(_amount>0,"amount must b graterthan 0");
      
    // uint256 tenPersontage = shoperPercentageAmount(_amount);
    // uint256 reminAmount = _amount-tenPersontage;
    // token.transferFrom(msg.sender,wallet_, tenPersontage);
    bool _transfer = token_.transferFrom(msg.sender,address(this),_amount);
     require(_transfer , "transfer failed");
    approve_[pIds]=perposal(pIds,false,false,false,_amount,msg.sender,_addr,0,0,block.timestamp,block.timestamp+acceptLimit_);
    }

    function offerComplete(address _addr, uint256 projectId)external{
    require(approve_[projectId].sender == msg.sender,"you dont assign this offer");
    require(approve_[projectId].reciver == _addr,"you enter address is wrong");
    approve_[projectId].time = true;
    approve_[projectId].timeStart = block.timestamp;
    approve_[projectId].timeEnd = block.timestamp + withdrawLimit_;//mints
    }

    
    function acceptOffer(uint256 projectId) nonReentrant external{  
    require(approve_[projectId].reciver == msg.sender,"dont have offer");
    require(approve_[projectId].accept == false,"you already accept this offer");
    require(approve_[projectId].deny == false,"you deny this offer");
    require(approve_[projectId].offerEnd>block.timestamp,"offer time ended, you lose the offer");
    
   // perposal storage project = approve_[projectId];
    
    uint256 tenPersontage = shoperPercentageAmount(approve_[projectId].amount);
    // uint256 reminAmount = project.amount-tenPersontage;
    //token.transferFrom(project.sender,wallet_, tenPersontage);
    
    bool _transfer = token_.transfer(wallet_, tenPersontage);
    require(_transfer , "transfer failed");
    approve_[projectId].amount=approve_[projectId].amount-tenPersontage;
    approve_[projectId].accept=true;
    }

    
    function refuseToOffer(uint256 projectId) nonReentrant public returns(string memory) {
    if(approve_[projectId].reciver == msg.sender){
    require(approve_[projectId].deny == false,"you already approve_");
    approve_[projectId].deny=true;
    // uint256 Transferamount = approve_[projectId].amount;
    bool _transfer = token_.transfer(approve_[projectId].sender, approve_[projectId].amount);
    require(_transfer , "transfer failed");
    approve_[projectId].amount = 0;
    return "sucessfull";
    }
    else {
        return "id not found";
    }
        
    }

   
    function withdraw(address _addr, uint256 projectId) nonReentrant external {
   
    if (approve_[projectId].accept == false && approve_[projectId].deny == false){
    require(approve_[projectId].reciver == _addr,"you enter address is wrong");
    require(review_[_addr].amontFreze == false,"please respone review_ request");
    require(approve_[projectId].offerEnd<block.timestamp,"please wait 48 hours");
    uint256 Transferamount = approve_[projectId].amount;
    bool _transfer = token_.transfer(msg.sender, Transferamount);
    require(_transfer , "transfer failed");
    approve_[projectId].amount = 0;

    }

    else if (approve_[projectId].accept == true && approve_[projectId].deny == false){
    require(review_[msg.sender].amontFreze == false,"please respone review_ request");
    require(approve_[projectId].reciver == msg.sender,"you are not the owner");
    require(approve_[projectId].time == true,"time is not started");
    require(approve_[projectId].timeEnd<=block.timestamp,"wait for withdraw time");
    uint256 twelve = freelancerPercentageAmount(approve_[projectId].amount);
    uint256 Transferamount = approve_[projectId].amount - twelve;
    bool _transfer = token_.transfer(msg.sender, Transferamount);
    require(_transfer , "transfer failed");
    bool _wallet_transfer = token_.transfer(wallet_, twelve);
    require(_wallet_transfer , "transfer failed");
    approve_[projectId].amount = 0;

    }
    
    }

    

    function getIdAddress(uint256 projectId) public view returns( perposal[] memory ){ 
        perposal[] memory items = new perposal[](projectId); 
        perposal storage currentItem = approve_[projectId]; 
        items[0] = currentItem; 
        return items; 
    }


    function changeRequest(address addr, uint256 projectId) public {
    require(approve_[projectId].sender == msg.sender,"you are not the shoper_");
    require(approve_[projectId].time == true,"time is not started"); 
    require(approve_[projectId].timeEnd > block.timestamp,"time is completed");
    if(approve_[projectId].reciver == addr){
    reviewId_.increment();
    uint256 rId = reviewId_.current();
    uint256 endTime=block.timestamp + reviewLimit_ ; //48 hours
    review_[addr]=Review(projectId,rId,block.timestamp,endTime,true);
    }
    }

    function reponse (uint256 projectId)public{
        require(approve_[projectId].reciver == msg.sender,"you are not a reciver");
        if(review_[msg.sender].reviewEnd < block.timestamp){
            review_[msg.sender].amontFreze = false; 
        }

    }


    function fetchIncomingOffer(address acount) public view returns (perposal[] memory) { 
        uint totalItemCount = projectIds_.current(); 
        uint itemCount = 0; 
        uint currentIndex = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve_[i + 1].reciver == acount) { 
        itemCount += 1; 
        } 
        } 
  
        perposal[] memory items = new perposal[](itemCount); 
        for (uint i = 0; i < totalItemCount; i++) { 
         if (approve_[i + 1].reciver ==acount) { 
         uint currentId = i + 1; 
        perposal storage currentItem = approve_[currentId]; 
        items[currentIndex] = currentItem; 
        currentIndex += 1; 
        } 
        } 
    return items; 
         } 


        function fetchOutgoingOffer(address acount) public view returns (perposal[] memory) { 
        uint totalItemCount = projectIds_.current(); 
        uint itemCount = 0; 
        uint currentIndex = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve_[i + 1].sender == acount) { 
        itemCount += 1; 
        } 
        } 
  
        perposal[] memory items = new perposal[](itemCount); 
        for (uint i = 0; i < totalItemCount; i++) { 
         if (approve_[i + 1].sender ==acount) { 
         uint currentId = i + 1; 
        perposal storage currentItem = approve_[currentId]; 
        items[currentIndex] = currentItem; 
        currentIndex += 1; 


        } 
        } 
    return items; 
         } 


    function getAllOffers(address account) public view returns(uint256){  
        uint totalItemCount = projectIds_.current(); 
        uint itemCount = 0; 
  
        for (uint i = 0; i < totalItemCount; i++) { 
        if (approve_[i + 1].reciver == account) { 
        itemCount += 1; 
        } 
        } 
            return itemCount;
        }

}
