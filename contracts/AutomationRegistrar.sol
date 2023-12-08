// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5.0 <0.9.0;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);

    function cancelUpkeep(uint256 id) external;
}
