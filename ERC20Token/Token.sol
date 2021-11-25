
pragma solidity ^0.6.2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract Token is IERC20 {
    string public override name;
    string public override symbol;
    uint8  public override decimals;
    uint256 tSupply;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);


    mapping (address => uint)                       public override balanceOf;
    mapping (address => mapping (address => uint))  public override allowance;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals) public{
        name = _name;
        symbol = _symbol;
        tSupply = _totalSupply;
        decimals = _decimals;
        balanceOf[msg.sender] = tSupply;
    }
    

    function totalSupply()override public view returns (uint) {
        return tSupply;
    }

    function approve(address guy, uint wad)override public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad)override public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)override
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

contract ERC20Factory {
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals) public{
       create(_name, _symbol, _totalSupply, _decimals);
    }
    
    function create(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals) private{
        Token t = new Token(_name, _symbol, _totalSupply, _decimals);
        t.transfer(msg.sender, _totalSupply);
    }
   
}