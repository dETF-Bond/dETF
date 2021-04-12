pragma solidity >=0.4.22 <0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = mul(z, base);
            return z;
        }
    }
}

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Accessible is Ownable {
    mapping(address => bool) public access;
    
    constructor() {
        access[msg.sender] = true;
    }
    
     modifier hasAccess() {
        require(checkAccess(msg.sender));
        _;
    }
    
    function checkAccess(address sender) public view returns (bool) {
        require(access[sender] == true);
        return true;
    }
    
    function removeAccess(address addr) public hasAccess returns (bool success) {
        access[addr] = false;
        return true;
    }
    
    function addAccess(address addr) public hasAccess returns (bool) {
        access[addr] = true;
        return true;
    }
}

contract ExternalAccessible {
    
    address public accessContract;

    function checkAccess(address sender) public returns (bool) {
        bool result = Accessible(accessContract).checkAccess(sender);
        require(result == true);
        return true;
    }

    modifier hasAccess() {
        require(checkAccess(msg.sender));
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is Context, IERC20, ExternalAccessible {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) external virtual hasAccess {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) external virtual hasAccess {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract DETF is ERC20 {
    
    constructor(address _accessContract) {
        _name = "dETF";
        _symbol = "dETF";
        _decimals = 18;
        accessContract = _accessContract;
    }
}

contract DETFAllocation is Ownable {
    using SafeMath for *;
    
    uint256 public teamAllocation;
    uint256 public treasuryAllocation;
    uint256 public IDOAllocation;
    uint256 public liquidityAllocation;
    uint256 public stakingAllocation;
    uint256 public marketingAllocation;
    
    address public stakingContract;
    
    uint256[] public teamReleaseSchedule;
    uint public lastTeamReleaseIndex;
    
    uint256[] public treasuryReleaseSchedule;
    uint public lastTreasuryReleaseIndex;
    
    DETF dETF;
    
    constructor(address dETFAddress) {
        teamAllocation = 0;
        IDOAllocation = 10000.mul(10.pow(18));
        liquidityAllocation = 15000.mul(10.pow(18));
        stakingAllocation = 20000.mul(10.pow(18));
        marketingAllocation = 15000.mul(10.pow(18));
        
        // The initial 8 dETF is to even out the distribution to the treasury. Without it the balance would end at 19,992
        treasuryAllocation = 8.mul(10.pow(18));
        
        // Generate team release schedule
        for (uint x = 0; x < 5; x++) {
           teamReleaseSchedule.push(block.timestamp + (x * 30 days)); 
        }
        
        // Generate treasury release schedule
        for (uint x = 0; x < 12; x++) {
           treasuryReleaseSchedule.push(block.timestamp + (x * 30 days)); 
        }
        
        dETF = DETF(dETFAddress);
    }
    
    // Any withdrawals made by the team will be logged.
    event NewWithdrawal(address authorizer, address recipient, uint256 amount, string reason);
    
    // Any account deposits will be logged.
    event NewDeposit(address authorizer, string recipient, uint256 amount);
    
   //  Any time the staking contract is changed, it will be logged so anyone can verify that contract address.
    event NewStakingContract(address authorizer, address oldContract, address newContract);
    
    // Anyone can add coins to one of the accounts in this contract.
    function deposit(uint256 amount, uint account) public {
        if (account == 1) {
            dETF._burn(msg.sender, amount);
            teamAllocation = teamAllocation.add(amount);
            NewDeposit(msg.sender, "Team Allocation", amount);
        }
         if (account == 2) {
            dETF._burn(msg.sender, amount);
            liquidityAllocation = liquidityAllocation.add(amount);
            NewDeposit(msg.sender, "Liquidity Allocation", amount);
        }
         if (account == 3) {
            dETF._burn(msg.sender, amount);
            stakingAllocation = stakingAllocation.add(amount);
            NewDeposit(msg.sender, "Staking Allocation", amount);
        }
         if (account == 4) {
            dETF._burn(msg.sender, amount);
            marketingAllocation = marketingAllocation.add(amount);
            NewDeposit(msg.sender, "Marketing Allocation", amount);
        }
         if (account == 5) {
            dETF._burn(msg.sender, amount);
            treasuryAllocation = treasuryAllocation.add(amount);
            NewDeposit(msg.sender, "Treasury Allocation", amount);
        }
    }
    
    function withdrawTeam(address recipient, uint256 amount) public onlyOwner {
        if (lastTeamReleaseIndex < 5) {
            if (block.timestamp > teamReleaseSchedule[lastTeamReleaseIndex]) {
                
                // Founders will receive 2000 dETF over the first 5 months for a total of 10,000 dETF
                teamAllocation = teamAllocation.add(2000.mul(10.pow(18)));
                lastTeamReleaseIndex = lastTeamReleaseIndex.add(1);
            }
        }
        teamAllocation = teamAllocation.sub(amount);
        dETF._mint(recipient, amount);
        emit NewWithdrawal(msg.sender, recipient, amount, "Team Allocation");
    }
    
    function withdrawTreasury(address recipient, uint256 amount) public onlyOwner {
        if (lastTreasuryReleaseIndex < 12) {
            if (block.timestamp > treasuryReleaseSchedule[lastTreasuryReleaseIndex]) {
                
                // The dETF treasury will receive 1,666 dETF over the first year for a total of 20,000 dETF
                treasuryAllocation = treasuryAllocation.add(1666.mul(10.pow(18))); 
                lastTreasuryReleaseIndex = lastTreasuryReleaseIndex.add(1);
            }
        }
        treasuryAllocation = treasuryAllocation.sub(amount);
        dETF._mint(recipient, amount);
        emit NewWithdrawal(msg.sender, recipient, amount, "Treasury Allocation");
    }
    
    function withdrawIDO(address recipient, uint256 amount) public onlyOwner {
        IDOAllocation = IDOAllocation.sub(amount);
        dETF._mint(recipient, amount);
        emit NewWithdrawal(msg.sender, recipient, amount, "IDO Allocation");
    }
    
    function withdrawLiquidity(address recipient, uint256 amount) public onlyOwner {
        liquidityAllocation = liquidityAllocation.sub(amount);
        dETF._mint(recipient, amount);
        emit NewWithdrawal(msg.sender, recipient, amount, "Liquidity Allocation");
    }
    
    function withdrawMarketing(address recipient, uint256 amount) public onlyOwner {
        marketingAllocation = marketingAllocation.sub(amount);
        dETF._mint(recipient, amount);
        emit NewWithdrawal(msg.sender, recipient, amount, "Marketing Allocation");
    }
    
    function withdrawStaking(uint256 amount) public {
        require(stakingContract != address(0));
        dETF._mint(stakingContract, amount);
        emit NewWithdrawal(msg.sender, stakingContract, amount, "Staking Rewards Allocation");
    }
    
    function changeStakingContract(address newContract) public onlyOwner {
        address oldStakingContract = stakingContract;
        stakingContract = newContract;
        emit NewStakingContract(msg.sender, oldStakingContract, stakingContract);
    }
    
}

