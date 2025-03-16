// SPDX license identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "src/EquationToken.sol";

contract DeployEquationToken is Script {
    function run() external {
        vm.startBroadcast();

        //address treasuryWallet = ;
        //EquationToken token = new EquationToken(treasuryWallet);

        //console.log("EquationToken deployed at address:", address(token));

        vm.stopBroadcast();
    }
}
