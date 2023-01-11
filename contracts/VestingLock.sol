// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VestingLock{
  using SafeMath for uint256;

  struct LockInfo {
    IERC20 token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
    bool isVesting;
  }

  struct VestingInfo {
    uint256 amount;
    uint256 unlockDate;
    bool isWithdrawn;
  }

  LockInfo public lockInfo;
  VestingInfo[] public vestingInfo;

  address public owner;
  address public lockFactory;

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }
  modifier onlyOwnerOrFactory() {
    require(msg.sender == owner || msg.sender == lockFactory, "ONLY_OWNER_OR_FACTORY");
    _;
  }
  event LogWithdraw(address to, uint256 lockedAmount);
  event LogWithdrawReflections(address to, uint256 amount);
  event LogWithdrawDividends(address to, uint256 dividends);
  event LogWithdrawNative(address to, uint256 dividends);
  event LogReceive(address from, uint256 value);

  constructor(
    address _owner,
    uint256 _unlockDate,
    uint256 _amount,
    address _token,
    address _factory,
    uint256 _tgePercent,
    uint256 _cycle,
    uint256 _cyclePercent,
    string memory _logoImage
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(_isValidVested(_tgePercent, _cyclePercent), "NOT_VALID_VESTED");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IERC20(_token);
    lockInfo.logoImage = _logoImage;
    lockInfo.isVesting = true;
    lockFactory = _factory;

    _initializeVested(_amount, _unlockDate, _tgePercent, _cycle, _cyclePercent);
  }

  function _isValidVested(uint256 tgePercent, uint256 cyclePercent) internal pure returns (bool) {
    return tgePercent + cyclePercent <= 100;
  }

  function _initializeVested(
    uint256 amount,
    uint256 unlockDate,
    uint256 tgePercent,
    uint256 cycle,
    uint256 cyclePercent
  ) internal {
    uint256 tgeValue = (amount * tgePercent) / 100;
    uint256 cycleValue = (amount * cyclePercent) / 100;
    uint256 tempAmount = amount - tgeValue;
    uint256 tempUnlock = unlockDate;

    VestingInfo memory vestInfo;

    vestInfo.amount = tgeValue;
    vestInfo.unlockDate = unlockDate;
    vestInfo.isWithdrawn = false;
    vestingInfo.push(vestInfo);

    while (tempAmount > 0) {
      uint256 vestCycleValue = tempAmount > cycleValue ? cycleValue : tempAmount;
      tempUnlock = tempUnlock + cycle;
      vestInfo.amount = vestCycleValue;
      vestInfo.unlockDate = tempUnlock;
      vestInfo.isWithdrawn = false;
      vestingInfo.push(vestInfo);
      tempAmount = tempAmount - vestCycleValue;
    }
  }

  function updateLogo(string memory newLogoImage) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    lockInfo.logoImage = newLogoImage;
  }

  function unlock() external onlyOwner {
    // solhint-disable-next-line not-rely-on-time,
    require(block.timestamp >= lockInfo.unlockDate, "WRONG_TIME");
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");

    uint256 unlocked = 0;
    for (uint256 i = 0; i < vestingInfo.length; i++) {
      // solhint-disable-next-line not-rely-on-time,
      if (!vestingInfo[i].isWithdrawn && vestingInfo[i].unlockDate < block.timestamp) {
        unlocked = unlocked + vestingInfo[i].amount;
        vestingInfo[i].isWithdrawn = true;
      }
    }
    if (unlocked == lockInfo.amount) {
      lockInfo.isWithdrawn = true;
    }

    lockInfo.token.transfer(owner, unlocked);

    emit LogWithdraw(owner, unlocked);
  }

  function getLockedValue() public view returns (uint256) {
    uint256 locked = 0;
    for (uint256 i = 0; i < vestingInfo.length; i++) {
      if (!vestingInfo[i].isWithdrawn) {
        locked = locked + vestingInfo[i].amount;
      }
    }
    return locked;
  }

  function withdrawBNB() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner).transfer(amount);
    emit LogWithdrawNative(owner, amount);
  }

  /**
   * for receive dividend
   */
  receive() external payable {
    emit LogReceive(msg.sender, msg.value);
  }
}