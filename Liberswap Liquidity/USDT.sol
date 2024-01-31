// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract USDT is ERC20 {
    constructor() ERC20("USDT Token", "USDT") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}