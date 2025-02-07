// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8); // Added decimals() function
}

contract TokenPresale {
    address public owner;
    address public USDTokenAddress;
    IERC20 public token; // Token being sold
    IERC20 public USDToken; // Token being sold

    uint256 public USDForOneToken; // Price of 1 token in USDT (or any ERC20 token)
    uint256 public totalTokensSold;
    uint256 public presaleEndTime;
    uint256 public USDTokenDecimals;
    uint256 public SaleTokenDecimals;
    bool public presaleActive;
    
    event TokensPurchased(address indexed buyer, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyDuringPresale() {
        require(presaleActive, "Presale is not active");
        require(block.timestamp < presaleEndTime, "Presale has ended");
        _;
    }
    
    constructor(address _TokenAddressForSale,address _USDTokenAddress, uint256 _presaleDurationInDays) {
        owner = msg.sender;
        token = IERC20(_TokenAddressForSale);
        USDToken = IERC20(_USDTokenAddress);
        USDTokenAddress=_USDTokenAddress;
        // Retrieve decimals from the token contract
        USDTokenDecimals = IERC20(_USDTokenAddress).decimals();
        SaleTokenDecimals = IERC20(_TokenAddressForSale).decimals();
        // Set token price: 0.1 USDT/token, considering token decimals
        USDForOneToken = (1 * 10**(USDTokenDecimals - 4)); // Represents 0.1 with token decimals
        
 
        presaleEndTime = block.timestamp + (_presaleDurationInDays * 1 days); // Convert days to seconds

        presaleActive = true;
    }

    function buyTokens(uint256 tokenAmount) external onlyDuringPresale {
        uint256 UserCostUSD = tokenAmount * USDForOneToken;
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient token send to user");
        require(USDToken.transferFrom(msg.sender, owner, UserCostUSD), "Recieve USDToken failed");  


        uint256   SendTokenAmount = (tokenAmount * 10**SaleTokenDecimals ); 
        require(token.transfer(msg.sender, SendTokenAmount), "Send Token failed");

        totalTokensSold += SendTokenAmount;
        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function endPresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        USDForOneToken = newPrice;
    }

    function getPresaleProgress() external view returns (uint256) {
        return (totalTokensSold * 100) / token.balanceOf(address(this));
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Withdrawal failed");
    }
}
