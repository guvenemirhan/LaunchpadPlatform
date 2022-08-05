//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ISwapRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract Pool{
    ISwapRouter private constant Router = ISwapRouter(/*Router address*/);
    address private immutable Receiver;
    IERC20 private immutable token;
    uint256 day;
    uint256 startTime;
    uint256 hardcap;
    uint256 softcap;
    uint256 minBuy;
    uint256 maxBuy;
    uint256 collectedAmount;
    uint256 liqPercent;
    uint256 presalePercent;
    uint256 presaleTokenBalance;
    address owner;
    uint256 isFinalized;
    mapping(address => uint256) presaleWallets;
    event Receipt(uint256 _collectedAmount);
    constructor(address _owner,address _admin ,address _tokenAddress, uint256 _totalTime,uint256 _startTime, uint256 _softcap, uint256 _hardcap, uint256 _minBuy, uint256 _maxBuy,uint256 _liqPercent,uint256 _presalePercent){
        token  = IERC20(_tokenAddress);
        day= _totalTime;
        startTime = _startTime;
        hardcap=_hardcap;
        softcap=_softcap;
        minBuy=_minBuy;
        maxBuy=_maxBuy;
        collectedAmount = 0;
        owner= _owner;
        liqPercent= _liqPercent;
        presalePercent= _presalePercent;
        Receiver = _admin;
    }
    modifier onlyAdmin(){
        require(msg.sender==Receiver,"You are not admin.");
        _;
    }
    modifier isAvailable(){
        uint256 endtime = 86400 * day + startTime;
        require(block.timestamp<= endtime,"Presale has ended.");
        require(collectedAmount<= hardcap, "Presale is over.");

        _;
    }
    modifier onlyOwner(){
        require(msg.sender== owner,"You are not owner.");
        _;
    }

    receive() external payable isAvailable{
        require(msg.value >= minBuy,"Less than the minimum buy amount.");
        require(msg.value <= maxBuy - presaleWallets[msg.sender] ,"Greater than the minimum buy amount.");
        presaleWallets[msg.sender]+=msg.value;
        collectedAmount += msg.value;
        emit Receipt(collectedAmount);
    }
    function contribute() public payable isAvailable{
        require(msg.value >= minBuy,"Less than the minimum buy amount.");
        require(msg.value <= maxBuy - presaleWallets[msg.sender] ,"Greater than the minimum buy amount.");
        presaleWallets[msg.sender]+=msg.value;
        collectedAmount += msg.value;
        emit Receipt(collectedAmount);
    }
    function finalize() external onlyOwner{
        uint256 endtime = 86400 * day + startTime;
        require(block.timestamp > endtime,"Presale not over yet.");
        require(collectedAmount>=softcap,"Softcap not reached.");
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance>0, "Token balance must greater than 0.");
        uint256 liqBalance = tokenBalance*liqPercent/100;
        uint256 liqBalanceWSlippage = liqBalance*90/100;
        presaleTokenBalance = tokenBalance-liqBalance;
        token.approve(address(Router),liqBalance);
        Router.addLiquidityETH{value: collectedAmount}(address(token),liqBalance,liqBalanceWSlippage,collectedAmount,owner,block.timestamp+10000);
        require(tokenBalance > token.balanceOf(address(this)),"Fail");
        isFinalized =1;
    }
    function getBalance() external view returns(uint256,uint256,uint256,uint256){
        uint256 tokenBalance= token.balanceOf(address(this));
        uint256 liqBalance = tokenBalance*liqPercent/100;
        return(tokenBalance,liqBalance,collectedAmount,address(this).balance);

    }
    function claim() external {
        require(isFinalized==1,"Presale is not over yet.");
        require(presaleWallets[msg.sender]>0,"You did not buy from presale.");
        uint256 multiple = collectedAmount / presaleWallets[msg.sender];
        uint256 amount = presaleTokenBalance / multiple;
        presaleWallets[msg.sender]=0;
        token.transfer(msg.sender,amount*98/100);
    }
    function emergencyWithdrawal() external payable{
        require(presaleWallets[msg.sender]>0,"You did not buy from presale.");
        uint256 amount =  presaleWallets[msg.sender] * 80 /100;
        collectedAmount -= presaleWallets[msg.sender];
        presaleWallets[msg.sender]=0;
        payable(msg.sender).transfer(amount);
    }
    function adminWithdraw() external onlyAdmin{
        require(address(this).balance>0);
        payable(msg.sender).transfer(address(this).balance);
    }
}