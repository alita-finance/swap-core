pragma solidity =0.5.16;

import './interfaces/IVSwapFactory.sol';
import './VSwapPair.sol';

contract VSwapFactory is IVSwapFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(VSwapPair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    bool public needAdminApproval;

    address public admin; // need admin approval to create a pool at the beginning

    bool public isSetSwapTime;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    modifier onlyAdmin(){
        require(admin == msg.sender, "VSwap: no permission");
        _;
    }
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        needAdminApproval = true;
        admin = msg.sender;
        isSetSwapTime = true;
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

    function changeSwapTimeSetting() external onlyAdmin{
        if(isSetSwapTime == true){
            isSetSwapTime = false;
        }
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, uint _startingSwapTime) external returns (address pair) {
        if(needAdminApproval == true){
            require(admin == tx.origin, "VSwap: no permission");
        }

        uint startingSwapTime = isSetSwapTime == false ? now: _startingSwapTime;
        // uint startingSwapTime = _startingSwapTime == 0 ? now: _startingSwapTime;
        require(tokenA != tokenB, 'VSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'VSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'VSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(VSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IVSwapPair(pair).initialize(token0, token1);
        IVSwapPair(pair).setSwapTime(startingSwapTime);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'VSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'VSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
