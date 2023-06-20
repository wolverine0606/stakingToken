// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//Create ERC20 token
//-
//-
//-
//-
contract MUTK is ERC20, AccessControl{   
    address public immutable owner;   
    uint public constant MAX_SUPPLY = 400000000 * (10 ** 18);//400m tokens  
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() ERC20("MU", "MU"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender); 
        _mint(msg.sender, MAX_SUPPLY);
        owner = payable(msg.sender);
    }
}


//Calculate an allowed amount of tokens that user can stake
//-
//-
//-
//-
contract calculation {
    uint public allowedAmountOfTokens;
    uint[9] public thresholds = [
            100000,
            250000,
            500000,
            1000000,
            2000000,
            3000000,
            5000000,
            7500000,
            10000000
    ];
    uint[9] public  prices = [0, 2500*10**18, 5000*10**18, 7500*10**18, 10000*10**18, 12500*10**18, 15000*10**18, 17500*10**18, 20000*10**18];

    function _allowedAmountOfTokens(uint currentAmountOfStakers, uint currentPriceOfToken) public returns(uint a){
        uint total_price_of_tokens = 0;
        uint i = 0;
        while (i < 9){
            if (currentAmountOfStakers > 10000000) {
                total_price_of_tokens = 25000*10**18;
            }
            if (currentAmountOfStakers < thresholds[i]) {
                total_price_of_tokens += prices[i];               
                break;
            }
            i++;           
        }
        allowedAmountOfTokens = (total_price_of_tokens / currentPriceOfToken)*10**18;

        return allowedAmountOfTokens;    
    }
}


// Buy/Sell functions
//-
//-
//-
//-
contract buyToken is MUTK {
    mapping(address => uint) public tokenBalance; 
    event Bougth(address receiver, uint amount);
    constructor(){

    }

    function mainTokenBalance() public view returns(uint){
        return balanceOf(owner);
    }

    function contractEtherBalance() public view returns(uint){
        return address(this).balance;
    }

    //automaticly buy tokens
    receive() external  payable{
        uint tokensToBuy = msg.value / 2;//1 wei = 1 token

        require(tokensToBuy > 0, "not enough funds");
        require(mainTokenBalance() > tokensToBuy, "not enough tokens");

        _mint(msg.sender, tokensToBuy);
        _burn(owner, tokensToBuy);
        tokenBalance[msg.sender] = tokensToBuy;

        emit Bougth(msg.sender, tokensToBuy);
    }

    function sell(uint amountToSell) public payable {
        uint allowance = allowance(msg.sender, address(this));

        require(amountToSell > 0 && tokenBalance[msg.sender] >= amountToSell, "incorrect amount");
        require(allowance >= amountToSell, "check allowance");

        _burn(msg.sender, amountToSell);
        tokenBalance[msg.sender] -= amountToSell;
        payable(msg.sender).transfer(amountToSell * 2);
    }
}


//SSSStaking contract
//-
//-
//-
//-
contract Staking is buyToken, calculation{
    using SafeMath for uint;
    uint public constant PLAN_DURATION = 26 weeks; 
    uint public constant BLOCK_PERIOD = 52 weeks;
    uint internal  totalStakers = 0;
    uint rewardRate = 10;//10 % from stake amount

    struct StakerData {
        uint totalStaked;
        uint lastStakedTimestamp;
        uint firstStakedTimestamp;
    }

    mapping(address => StakerData) public stakingBalance;

    function calculateReward(address user) public view returns(uint){
        // StakerData storage staker = stakingBalance[user];
        // uint
    }
    
    function stake(uint amount) public {
        StakerData storage staker = stakingBalance[msg.sender];  
        uint tokenLimit = _allowedAmountOfTokens(3000001/*current amount of stakers*/, 1000000000000000000/*current price of token in wei*/);

        require(amount > 0, "Amount must be greater than 0");
        require(tokenLimit > 0, "staking is not available");
        require(amount <= tokenLimit, "ur over limit");  

        _burn(msg.sender, amount);

        //update staker information
        staker.totalStaked = staker.totalStaked.add(amount); 
        staker.lastStakedTimestamp = block.timestamp;

    }

    function unstake(uint amount) public {
        StakerData storage staker = stakingBalance[msg.sender];

        require(staker.totalStaked >= amount);
        require(amount > 0, "Amount must be greater than 0");

        _mint(msg.sender, amount);

    }
}
