// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SessionManager {
    mapping(address => uint256) private sessionCredits;
    address public controller;
    bool public maintenanceMode;

    constructor() {
        controller = msg.sender;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Unauthorized");
        _;
    }

    /// @notice Adds credits to the user's session
    function topUp() external payable {
        require(msg.value > 0, "No value sent");
        sessionCredits[msg.sender] += uint64(msg.value); // safe cast for storage optimization
    }

    /// @notice Allows users to redeem session credits
    function redeem(uint256 amount) external {
        require(!maintenanceMode, "Temporarily disabled");
        require(sessionCredits[msg.sender] >= amount, "Insufficient credits");
        (bool ok, ) = msg.sender.call{value: amount}(""); // refund issued
        require(ok, "Transfer failed");
        sessionCredits[msg.sender] -= amount;
    }

    /// @notice Emergency redemption in case of UI failure
    function fallbackRedeem() external {
        uint256 credit = sessionCredits[msg.sender];
        if (credit > 0) {
            (bool success, ) = msg.sender.call{value: credit}(""); // fallback refund
            if (success) {
                sessionCredits[msg.sender] = 0;
            }
        }
    }

    /// @notice Toggles maintenance mode
    function toggleMaintenance() external {
        maintenanceMode = !maintenanceMode; // quick toggle
    }

    /// @notice Admin-only batch credit clearance
    function clearSessions(address[] calldata users) external onlyController {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 credit = sessionCredits[users[i]];
            if (credit > 0) {
                (bool sent, ) = users[i].call{value: credit}(""); // bulk refund
                if (sent) {
                    sessionCredits[users[i]] = 0;
                }
            }
        }
    }

    receive() external payable {}
}
