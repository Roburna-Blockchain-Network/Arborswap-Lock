
ARBORSWAP LOCK

1. constructor accepts 3 arguments: feeAddr (payable address to receive fees for locking tokens),
feeNormal(a fee for deploying normal lock),
feeVesting(a fee for deploying vesting lock)

2. to create normal lock, a user should call lock() function with following arguments
  1. Lock owner address
  2. token address
  3. isLpToken (true or false, true if it is lp, false if it is not)
  4. amount 
  5. unlockDate
  6. description (a string)

3. to create a vesting lock, a user should call vestingLock() function with following arguments
  1. Lock owner address
  2. token address
  3. isLpToken (true or false, true if it is lp, false if it is not)
  4. amount 
  5. tgeDate (time when tge portion is unlocked)
  6. tgeBps - tge portion percentage from total of 10000
  7. cycle - how many vesting portions ?
  8. cycleBps - vesting portion size percentage from total of 10000
  9. Sum of TGE bps and cycle BPS should be less than 10000

4. multipleVestingLock(), allows to create a vesting lock for multiply users
arguments: 
  1. owners array
  2. amounts array 
  3. token address
  4. isLpToken (true or false, true if it is lp, false if it is not)
  5. tgeDate (time when tge portion is unlocked)
  6. tgeBps - tge portion percentage from total of 10000
  7. cycle - how many vesting portions ?
  8. cycleBps - vesting portion size percentage from total of 10000
  9. Sum of TGE bps and cycle BPS should be less than 10000

5. withdrawableTokens() vieew function to get withdrawable amount  of particular lock. Just pass the lock id

6. editLock() -  a function to edit lock. Only possible to edit if the lock wasn't unlocked. Only possible to add more tokens to lock and increase unlock date

7. editLockDescription()  lock owner can edit lock description

8. transferLockOwnership() - lock onwership can be transferred

9. renounceLockOwnership() - transfer lock ownership to address 0

10. updateFeeAddr() - a function for owner to update fee adderess

11. updateFeeNormal() - a function for owner to update fee for normal lock

12. updateFeeVesting() - a function for owner to update fee for vetsing lock