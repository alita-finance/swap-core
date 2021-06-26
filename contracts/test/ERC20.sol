pragma solidity =0.5.16;

import '../AlitaSwapERC20.sol';

contract ERC20 is AlitaSwapERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
