// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TokenLockDividendsAndReflections {
  using SafeMath for uint256;

  bool public isReward;

  struct LockInfo {
    IERC20 token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
    bool isVesting;
  }

  LockInfo public lockInfo;

  address public owner;
  address public lockFactory;

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }
  modifier onlyRewardLock() {
    require(isReward == true, "ONLY_REWARDLOCK");
    _;
  }
  modifier onlyOwnerOrFactory() {
    require(msg.sender == owner || msg.sender == lockFactory, "ONLY_OWNER_OR_FACTORY");
    _;
  }

  event LogExtendLockTime(uint256 oldUnlockTime, uint256 newUnlockTime);
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
    string memory _logoImage,
    bool _isReward
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IERC20(_token);
    lockInfo.logoImage = _logoImage;
    lockInfo.isVesting = false;
    isReward = _isReward;
    lockFactory = msg.sender;
  }

  function extendLockTime(uint256 newUnlockDate) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    uint256 oldDate = lockInfo.unlockDate;

    // solhint-disable-next-line not-rely-on-time,
    require(newUnlockDate >= lockInfo.unlockDate && newUnlockDate > block.timestamp, "BAD_TIME_INPUT");
    lockInfo.unlockDate = newUnlockDate;

    emit LogExtendLockTime(oldDate, newUnlockDate);
  }

  function updateLogo(string memory newLogoImage) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    lockInfo.logoImage = newLogoImage;
  }

  function unlock() external onlyOwner {
    // solhint-disable-next-line not-rely-on-time,
    require(block.timestamp >= lockInfo.unlockDate, "WRONG_TIME");
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");

    lockInfo.isWithdrawn = true;

    lockInfo.token.transfer(owner, lockInfo.amount);

    emit LogWithdraw(owner, lockInfo.amount);
  }

  function withdrawReflections() external onlyRewardLock onlyOwner {
    if (lockInfo.isWithdrawn) {
      uint256 reflections = lockInfo.token.balanceOf(address(this));
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    } else {
      uint256 contractBalanceWReflections = lockInfo.token.balanceOf(address(this));
      uint256 reflections = contractBalanceWReflections - lockInfo.amount;
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    }
  }

  function withdrawDividends(address _token) external onlyRewardLock onlyOwner {
    require(_token != address(lockInfo.token), "CANT_WITHDRAW_LOCKED_ASSETS");
    uint256 dividends = IERC20(_token).balanceOf(address(this));
    if (dividends > 0) {
      IERC20(_token).transfer(owner, dividends);
    }
    emit LogWithdrawDividends(owner, dividends);
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
