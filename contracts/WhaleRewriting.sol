pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './RewritingUtilities.sol';

contract WhaleRewriting is ERC20PresetMinterPauser, Ownable {
    
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    // AntiWhale
    mapping (address => bool) public _isExcludedFromAntiWhale;
    bool public inProtection = false;
    bool public whaleSystemActive = true;
    mapping (address => uint256) public _lastTransactionTime;
    mapping (address => uint256) public _amountSentByAddress;
    uint256 public timeToWaitBeforeTransactionSentReset = 86400; // a day
    uint256 public maxTransferInPeriod = 2 * 10**3 * 10**6 * 10**18; // a day
    uint256 public choosenTotalSupply = 10**9 * 10**6 * 10**18;

    constructor() ERC20PresetMinterPauser('FakeWhaleV2', 'FW2') {
        mint(_msgSender(), choosenTotalSupply);
        //Create a uniswap pair for this new token
        
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancakeSwap
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());
        // _isExcludedFromAntiWhale[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
        // _isExcludedFromAntiWhale[_uniswapV2Router.factory()] = true;
        // _isExcludedFromAntiWhale[uniswapV2Pair] = true;
        
        //TEST
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //PancakeSwapTestRouter
        // uniswapV2Pair = IUniswapV2Factory(0x6725F303b657a9451d8BA641348b6761A6CC7a17).createPair(address(this), _uniswapV2Router.WETH());
        // uniswapV2Router = _uniswapV2Router;
        // _isExcludedFromAntiWhale[0xD99D1c33F9fC3444f8101754aBC46c52416550D1] = true;
        // _isExcludedFromAntiWhale[0x6725F303b657a9451d8BA641348b6761A6CC7a17] = true;
        // _isExcludedFromAntiWhale[uniswapV2Pair] = true;
        // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
        mint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 2 * 10**18);
        mint(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 2 * 10**18);
        
        _isExcludedFromAntiWhale[_msgSender()] = true;
    }
    
    function changeProtectionStatus(bool newValue) external onlyOwner {
        inProtection = newValue;
    }
    
    function changeWhaleSystem(bool newValue) external onlyOwner {
        whaleSystemActive = newValue;
    }
    
    function changeTimeToWaitBeforeTransactionSentReset(uint256 newValue) external onlyOwner {
        timeToWaitBeforeTransactionSentReset = newValue;
    }
    
    function changeMaxTransferInPeriod(uint256 newValue) external onlyOwner {
        maxTransferInPeriod = newValue;
    }
    
    function senderCouldNotSendMoreThanMaxForPeriod(address sender, uint256 amount) internal virtual {
        if (whaleSystemActive && _isExcludedFromAntiWhale[sender] == false) {
            uint256 lastTimeSenderSent = _lastTransactionTime[sender];
            if (block.timestamp >= lastTimeSenderSent + timeToWaitBeforeTransactionSentReset) {
                _lastTransactionTime[sender] = block.timestamp;
                lastTimeSenderSent = block.timestamp;
                _amountSentByAddress[sender] = amount;    
            } else {
                require(_amountSentByAddress[sender] + amount <= maxTransferInPeriod);
                _amountSentByAddress[sender] += amount;    
            }
        }
    }
    
    bool public transferOnceForPeriod = true;
    function changeTransferOnceForPeriod(bool newValue) external onlyOwner {
        transferOnceForPeriod = newValue;
    }
    
    function buyerCantDoTransferAgainForPeriod(address sender, address recipient) internal virtual {
          if (whaleSystemActive && transferOnceForPeriod && _isExcludedFromAntiWhale[sender] == true) {
            _lastTransactionTime[recipient] = block.timestamp;
            _amountSentByAddress[recipient] = maxTransferInPeriod;    
        }   
    }
    
    bool public betweenWalletConstraint = true;
    function changeBetweenWalletConstraint(bool newValue) external onlyOwner {
        betweenWalletConstraint = newValue;
    }
    function penalizeTransferBetweenWallets(address sender, address recipient) internal virtual {
        if (whaleSystemActive && betweenWalletConstraint && _isExcludedFromAntiWhale[sender] == false && _isExcludedFromAntiWhale[recipient] == false) {
            _lastTransactionTime[sender] = block.timestamp + maxTransferInPeriod.mul(4);
            _amountSentByAddress[sender] = maxTransferInPeriod;
            _lastTransactionTime[recipient] = block.timestamp + maxTransferInPeriod.mul(4);
            _amountSentByAddress[recipient] = maxTransferInPeriod;    
        }
    }
    
    function _transfer(address sender, address recipient, uint256 amount) override internal virtual {
        require(inProtection == false);
        senderCouldNotSendMoreThanMaxForPeriod(sender, amount);
        buyerCantDoTransferAgainForPeriod(sender, recipient);
        penalizeTransferBetweenWallets(sender, recipient);
        super._transfer(sender, recipient, amount);
    }
    
    
    uint256 preSaleTokens =  10**9 * 10**6 * 10**18;
    function setupPreSaleContract(address preSaleContract) external onlyOwner {
        _isExcludedFromAntiWhale[preSaleContract] = true;
        transfer(preSaleContract, balanceOf(owner()));
    }
}
