pragma solidity =0.5.16;

import './interfaces/IPancakeFactory.sol';
import './PancakePair.sol';

contract PancakeFactory is IPancakeFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(PancakePair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    bool public needAdminApproval;

    address public admin; // need admin approval to create a pool at the beginning

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    modifier onlyAdmin(){
        require(admin == msg.sender, "Pancake: no permission");
        _;
    }
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        needAdminApproval = true;
        admin = msg.sender;
    }

    function setAdminApproval() external onlyAdmin{
        if(needAdminApproval == true){
            needAdminApproval = false;
        }
    }

    function changeAdmin(address _newAd) external onlyAdmin{
        require(_newAd != address(0));
        admin = _newAd;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, uint _startingSwapTime) external returns (address pair) {
        if(needAdminApproval == true){
            require(admin == msg.sender, "Pancake: no permission");
        }

        uint startingSwapTime = _startingSwapTime == 0 ? now: _startingSwapTime;
        require(tokenA != tokenB, 'Pancake: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Pancake: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Pancake: PAIR_EXISTS'); // single check is sufficient
        // bytes memory bytecode = type(PancakePair).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // assembly {
        //     pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        // }

        bytes memory bytecode = type(PancakePair).creationCode;
        bytes memory deployedByteCode = abi.encodePacked(bytecode, abi.encode(startingSwapTime));
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(deployedByteCode, 32), mload(deployedByteCode), salt)
        }
        IPancakePair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
