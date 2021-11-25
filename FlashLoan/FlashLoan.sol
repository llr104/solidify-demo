pragma solidity ^0.6.2;

contract Ownable{
   
    address public owner;
    mapping(address=>bool) public Manager;

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "NOT_CURRENT_OWNER");
        _;
    }

}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}
library SafeMath {
    int256 constant private INT256_MIN = -2**255;
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/*
    闪电贷
*/
contract FlashLoan is Ownable{
    
    using SafeMath for uint256;
    using address_make_payable for address;
    uint256 interestPercentage = 1; // 借出金额收取1%利息
    
    // 闪电贷-ETH
    function flashLoanByEth(address contractAddress, uint256 value) public payable returns(uint256, uint256){
        // 查询当前合约ETH余额
        uint256 beforeBalance = address(this).balance;
        require(beforeBalance >= value,"transfer value should be less than balance");
        // 利息
        uint256 interestValue = value.mul(interestPercentage).div(100); 
        address payable addr = contractAddress.make_payable();
        (bool success,) = addr.call{value: value}(abi.encodeWithSignature("implementFlashLoanByEth(uint256,uint256)",value,interestValue));
        require(success,"call is fail 1");
        //  查询当前合约ETH余额
        uint256 afterBalance = address(this).balance;
        // 合约初始余额 + 利息 = 结束余额
        require(beforeBalance + interestValue == afterBalance,"flashLoan is error");
        
        return(value, interestValue);
    }
    // 闪电贷-ERC20
    function flashLoanByErc(address contractAddress, address token,uint256 value) public returns(uint256,uint256) {
        ERC20 erc20 = ERC20(token);
        uint256 beforeBalance = erc20.balanceOf(address(this));
        require(beforeBalance >= value,"transfer value should be less than balance");
        // 利息
        uint256 interestValue = value.mul(interestPercentage).div(100);
        erc20.transfer(contractAddress,value);
        (bool success,) = contractAddress.call(abi.encodeWithSignature("implementFlashLoanByErc(uint256,uint256,address)",value,interestValue,token));
        require(success,"call is fail 1");
        //  查询当前合约ERC20余额
        uint256 afterBalance = erc20.balanceOf(address(this));        
        // 合约初始余额 + 利息 = 结束余额
        require(beforeBalance + interestValue == afterBalance,"flashLoan is error");
        return(value, interestValue);
        
    }
    
    // 充值资金进来，作为可准许借出资产
    function receiveEth() public payable{
        
    }
    
    function repayEth(address accountAddress, uint256 value) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= value,"value should be less than balance");
        
        address payable addr = accountAddress.make_payable();
        addr.transfer(value);
    }
    
    function repayERC20(address accountAddress, address token, uint256 value) external onlyOwner {
        ERC20 erc20 = ERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance >= value,"value should be less than balance");
        erc20.transfer(accountAddress, value);
    }
    
    function ETHBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function ERC20Balance(address token) public view returns(uint256){
        return ERC20(token).balanceOf(address(this));
    }
        

}

contract FlashLoanReceiver is Ownable{
    
    using address_make_payable for address;
    using SafeMath for uint256;


    
    function implementFlashLoanByEth(uint256 value,uint256 interestValue) public payable{
        // 添加业务
        
        // 借的资金加上利息，还回去
        (bool success,) = (msg.sender).call{value: value.add(interestValue)}(abi.encodeWithSignature("receiveEth()"));
        require(success,"call is fail 2");
        
    }
    
    function implementFlashLoanByErc(uint256 value,uint256 interestValue,address token) public{
        // 添加业务
        
        // 借的资金加上利息，还回去
        ERC20 erc20 = ERC20(token);
        erc20.transfer(msg.sender,value.add(interestValue));
    }
    

    // 充值资金进来，用于支付利息
    function receiveEth() public payable{
        
    }
    
    
    function repayEth(address accountAddress, uint256 value) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= value,"value should be less than balance");
        
        address payable addr = accountAddress.make_payable();
        addr.transfer(value);
    }
    
    function repayERC20(address accountAddress, address token, uint256 value) external onlyOwner {
        ERC20 erc20 = ERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance >= value,"value should be less than balance");
        erc20.transfer(accountAddress, value);
    }
    
    function ETHBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function ERC20Balance(address token) public view returns(uint256){
        return ERC20(token).balanceOf(address(this));
    }

}

