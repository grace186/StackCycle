# StackCycle Smart Contract

A blockchain-based recycling rewards system built on Stacks, incentivizing sustainable waste management through verifiable tracking and token rewards.

## Overview

StackCycle is a smart contract that enables recycling centers to verify and reward users for their recycling contributions. The system tracks recycling submissions, manages reward points, and allows users to claim STX tokens as rewards.

## Features

- **Recycling Verification**: Approved centers can verify recycling submissions
- **Point-Based Rewards**: Users earn points based on recycled items
- **Token Rewards**: Points can be converted to STX tokens
- **History Tracking**: Complete record of user recycling activities
- **Admin Controls**: Managed system for centers and product types

## Contract Functions

### Admin Functions

```clarity
(register-center (center principal))
(disable-center (center principal))
(add-product-type (type-id (buff 32)) (name (string-ascii 30)) (reward uint))
(disable-product-type (type-id (buff 32)))
(set-reward-threshold (new-threshold uint))
```

### Core Functions

```clarity
(submit-recycle (user principal) (type-id (buff 32)) (quantity uint))
(claim-reward)
```

### Read-Only Functions

```clarity
(get-user-points (user principal))
(get-product-type (type-id (buff 32)))
(is-center? (center principal))
(get-claimed (user principal))
(get-user-submissions (user principal))
(get-user-history (user principal) (index uint))
(get-reward-threshold)
(get-unclaimed-points (user principal))
```

## Error Codes

| Code | Description |
|------|-------------|
| u401 | Unauthorized |
| u402 | Not enough points |
| u403 | Not an approved center |
| u404 | Product type not found |
| u405 | No reward to claim |
| u406 | STX transfer failed |
| u407 | Invalid quantity |
| u408 | Arithmetic overflow |
| u409 | Product type disabled |

## Getting Started

1. Deploy the contract to the Stacks blockchain
2. Set up initial admin configuration
3. Register recycling centers
4. Add product types with reward values
5. Begin tracking recycling submissions

## Security Considerations

- Admin-only access for sensitive operations
- Protected state mutations
- Arithmetic overflow protection
- Validation checks on all inputs

