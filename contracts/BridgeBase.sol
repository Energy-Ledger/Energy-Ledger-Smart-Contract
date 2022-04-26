
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";


interface IELX {
    function transferFrom( address sender, address recipient, uint256 amount) external ;
    function transfer(address recipient, uint256 amount) external ;
}

contract BridgeBase is Ownable
{
    address public admin;

    uint256 public tokenSwapFee;
    uint256 public totalDepositedFee;
    uint256 public depositedFee;

    address tokenAddress;

     // Events 
    event AuthorizedCaller(address _caller);
    event DeAuthorizedCaller(address _caller);

    event UpdateSwapFee(address indexed _operator, uint256 _fee);
    event UpdateWithdrawFee(address indexed _operator, uint256 _depositedFee);
    event ELXDeposited(address indexed _account, uint256 _amount, uint _nonce);
    event ELXDepositedClaimed(address indexed _account, uint256 _amount, uint _nonce);
    event emergencyELXWithdrawal(address indexed _account, uint256 _amount);

     // List of authorizedCaller with escalated permissions
    mapping(address => mapping(uint => bool)) public processedNoncesMap;
    mapping(address => uint) public processedNonces;
    mapping(address => bool) public authorizedCaller;

    constructor(address _tokenAddress) {
        admin = msg.sender;   
        setTokenAddress(_tokenAddress); 
    }

    modifier onlyAuthCaller() {
        require(
            authorizedCaller[msg.sender] == true || msg.sender == owner,
            "Only Authorized and Owner can perform this action"
        );
        _;
    }

    function authorizeCaller(address _caller) public onlyOwner returns (bool) {
        authorizedCaller[_caller] = true;
        emit AuthorizedCaller(_caller);
        return true;
    }

    function deAuthorizeCaller(address _caller)
        public
        onlyOwner
        returns (bool)
    {
        authorizedCaller[_caller] = false;
        emit DeAuthorizedCaller(_caller);
        return true;
    }

    /*SetSwap fee */
    function setSwapFee(uint256 _tokenSwapFee) public onlyAuthCaller returns(bool)
    {
        tokenSwapFee = _tokenSwapFee;
        emit UpdateSwapFee(msg.sender,_tokenSwapFee);
        return true;
    }

    function withdrawDepositedFee() public onlyAuthCaller returns(bool)
    {
        address payable _receiver = payable(msg.sender);
        require(depositedFee > 0,"Insufficient balance");
        _receiver.transfer(depositedFee);

        emit UpdateWithdrawFee(msg.sender,depositedFee);
        depositedFee  = 0;
        return true;
    }

     /* get token address */
    function getTokenAddress() public view returns (address _tokenAddress) {        
        return (tokenAddress);
    }

     /* set token address */
    function setTokenAddress(address _tokenAddress) public onlyAuthCaller {           
        tokenAddress = _tokenAddress;
    }


    function depositAmount(uint256 amount, uint _nonce) external payable {
        
        require(processedNoncesMap[msg.sender][_nonce] == false, 'Transfer already processed');
        processedNoncesMap[msg.sender][_nonce] = true;
        processedNonces[msg.sender]+=1;

   
        string memory _invalidMessage = string(abi.encodePacked('Invalid Fee, Expected fee in wei : ',uint2str(tokenSwapFee)));
        
        require(msg.value == tokenSwapFee, _invalidMessage);

        totalDepositedFee += msg.value;
        depositedFee  += msg.value;


        IELX(tokenAddress).transferFrom(msg.sender,address(this),amount);

        emit ELXDeposited(msg.sender,amount,_nonce);
    }

    function claimDeposit(address _to, uint256 amount ,uint _nonce) external onlyAuthCaller
    {
        require(processedNoncesMap[address(this)][_nonce] == false, 'transfer already processed');
        processedNoncesMap[address(this)][_nonce] = true;
        processedNonces[address(this)]+=1;

        IELX(tokenAddress).transfer(_to,amount);
        // emit Transfer(address(0), _to, amount);
        emit ELXDepositedClaimed(msg.sender,amount,_nonce);
      
    }


    function uint2str(uint _i) internal pure returns (string memory uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function emergencyELXWithdraw(uint256 amount) public onlyAuthCaller returns(bool)
    {
         IELX(tokenAddress).transfer(msg.sender,amount);
        emit emergencyELXWithdrawal(msg.sender,amount);
        return true;
    }
}