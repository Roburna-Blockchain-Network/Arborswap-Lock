// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./ArborSwapDeps/IUniswapV2Pair.sol";
import "./ArborSwapDeps/IUniswapV2Factory.sol";

contract LiquidityLock {
  using SafeMath for uint256;

  struct LockInfo {
    IUniswapV2Pair token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
  }

  LockInfo public lockInfo;

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

  event LogExtendLockTime(uint256 oldUnlockTime, uint256 newUnlockTime);
  event LogWithdraw(address to, uint256 lockedAmount);
  event LogWithdrawNative(address to, uint256 dividends);
  event LogReceive(address from, uint256 value);

  constructor(
    address _owner,
    uint256 _unlockDate,
    uint256 _amount,
    address _token,
    address _factory,
    string memory _logoImage
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IUniswapV2Pair(_token);
    lockInfo.logoImage = _logoImage;
    lockFactory = _factory;
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
