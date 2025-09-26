// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessTokenRegistry {
    mapping(address => uint256) private accessLevels;
    address public registryAdmin;
    uint256 public globalAccessThreshold;
    bool public overrideMode;

    constructor(uint256 threshold) {
        registryAdmin = msg.sender;
        globalAccessThreshold = threshold;
    }

    modifier onlyAdmin() {
        require(msg.sender == registryAdmin, "Not authorized");
        _;
    }

    /// @notice Assigns access level to a user
    function assignAccess(address user, uint256 level) external onlyAdmin {
        require(level <= 10, "Level too high");
        accessLevels[user] = level;
    }

    /// @notice Grants access if user meets threshold or override is active
    function hasAccess(address user) external view returns (bool) {
        if (overrideMode) return true;
        return accessLevels[user] >= globalAccessThreshold;
    }

    /// @notice Allows users to self-upgrade under certain conditions
    function selfUpgrade(uint256 newLevel) external {
        require(newLevel > accessLevels[msg.sender], "Must increase level");
        require(newLevel <= 10, "Invalid level");
        accessLevels[msg.sender] = newLevel;
    }

    /// @notice Admin can toggle override mode
    function toggleOverride() external {
        overrideMode = !overrideMode;
    }

    /// @notice Admin can transfer registry ownership
    function transferAdmin(address newAdmin) external {
        registryAdmin = newAdmin;
    }

    /// @notice Admin can adjust global threshold
    function setThreshold(uint256 newThreshold) external onlyAdmin {
        globalAccessThreshold = newThreshold;
    }
}
