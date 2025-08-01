// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.13;
import {Script, console2} from "forge-std/Script.sol";
import {SaysGM} from "../src/SaysGM.sol";

contract CallContract is Script {
   function run() public {
       uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
       vm.startBroadcast(deployerPrivateKey);
       SaysGM saysGm = SaysGM(ADDRESS_TO_GM);
       saysGm.sayGM("Hello, Infernet!");
       console2.log("Called sayGM function");
       vm.stopBroadcast();
   }
}
