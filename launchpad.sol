//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pool.sol";
interface IPool {
    function adminWithdraw() external;
}

contract Launchpad{
    address[] presaleAddresses;
    uint256 launchpadPrice= .001 ether;
    uint256 createdPool;
    address private immutable owner;
    event PoolCreated(address pool);
    constructor(){
        owner=msg.sender;
    }
    receive() external payable {
        
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"You are not owner.");
        _;
    }
    function createPresale(address token, uint256 _totalTime,uint256 _startTime,uint256 _softcap,uint256 _hardcap,uint256 _minBuy,uint256 _maxBuy,uint256 _liqPercent,uint256 _presalePercent,uint256 tokenAmount) public payable {
        require(msg.value>launchpadPrice);
        bytes32 salt = keccak256(abi.encodePacked(token, address(this)));
        bytes memory bytecode = type(Pool).creationCode;
        bytes memory creationCode= abi.encodePacked(bytecode, abi.encode(msg.sender,address(this),token,_totalTime,_startTime,_softcap,_hardcap,_minBuy,_maxBuy,_liqPercent,_presalePercent));
        address addr;
        assembly {
            addr := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        bytes32 _salt= salt;
        address tokenAddress = token;

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(creationCode)
            )
        );
        address pool= address(uint160(uint(hash)));
        presaleAddresses.push(pool);
        IERC20(tokenAddress).transferFrom(msg.sender,pool,tokenAmount);
        emit PoolCreated(pool);
    }
    function adminWithdraw() external onlyOwner{
        uint256 _counter=createdPool;
        for(uint256 i = createdPool ; i< presaleAddresses.length; i++){
            if(presaleAddresses[i].balance>0){
                (bool success,) = presaleAddresses[i].call(abi.encodeWithSignature("adminWithdraw()"));
            }
            _counter++;
        }
        createdPool=_counter;
    }
    function getPoolAddress(address token, uint256 _totalTime,uint256 _startTime,uint256 _softcap,uint256 _hardcap,uint256 _minBuy,uint256 _maxBuy,uint256 _liqPercent,uint256 _presalePercent) external view returns(address){
        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token, address(this)));
        bytes memory creationCode= abi.encodePacked(bytecode, abi.encode(msg.sender,address(this),token,_totalTime,_startTime,_softcap,_hardcap,_minBuy,_maxBuy,_liqPercent,_presalePercent));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), salt, keccak256(creationCode)
            )
        );
        return address (uint160(uint(hash)));
    }
}