🛡️ Blockchain-powered savings circles that protect rural communities from inflation

## 🌟 Overview

Traditional rural savings groups lose value due to high inflation rates. This smart contract creates **inflation-protected savings circles** using blockchain technology and automatic inflation adjustments.

## ✨ Features

- 🏪 **Create Savings Groups**: Form community savings circles with transparent governance
- 👥 **Member Management**: Join/leave groups with full transparency
- 💵 **Smart Deposits**: Automatic inflation tracking from deposit time
- 📈 **Inflation Protection**: Real-time balance adjustments based on configured inflation rates
- 💸 **Protected Withdrawals**: Withdraw inflation-adjusted amounts
- 📊 **Transparent Records**: All transactions logged and verifiable on-chain
- 🎯 **Savings Goals**: Members can set personal savings targets and track progress
- ⚙️ **Configurable Inflation**: Admin can update inflation rates as economic conditions change

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Inflation-Protected-Village-Savings
clarinet check
```

## 📋 Usage

### 1. Create a Savings Group
```clarity
(contract-call? .Inflation-Protected-Village-Savings create-savings-group "Village Women Group")
```

### 2. Join a Group
```clarity
(contract-call? .Inflation-Protected-Village-Savings join-group u1)
```

### 3. Deposit Funds
```clarity
(contract-call? .Inflation-Protected-Village-Savings deposit u1 u1000000)
```

### 4. Check Your Balance (with inflation adjustment)
```clarity
(contract-call? .Inflation-Protected-Village-Savings get-member-info u1 'SP1...)
```

### 5. Withdraw Funds (inflation-protected amount)
```clarity
(contract-call? .Inflation-Protected-Village-Savings withdraw u1 u500000)
```

### 6. Set Savings Goal
```clarity
(contract-call? .Inflation-Protected-Village-Savings set-savings-goal u1 u5000000)
```

### 7. Leave Group (get full inflation-adjusted balance)
```clarity
(contract-call? .Inflation-Protected-Village-Savings leave-group u1)
```

## 🔧 Admin Functions

### Update Inflation Rate
```clarity
(contract-call? .Inflation-Protected-Village-Savings update-inflation-rate u350)
```

### Deactivate Group
```clarity
(contract-call? .Inflation-Protected-Village-Savings deactivate-group u1)
```

## 📊 Query Functions

### Group Information
```clarity
(contract-call? .Inflation-Protected-Village-Savings get-group-info u1)
(contract-call? .Inflation-Protected-Village-Savings get-group-stats u1)
```

### Member Information
```clarity
(contract-call? .Inflation-Protected-Village-Savings get-member-info u1 'SP1...)
(contract-call? .Inflation-Protected-Village-Savings get-member-adjusted-balance u1 'SP1...)
(contract-call? .Inflation-Protected-Village-Savings get-savings-goal-progress u1 'SP1...)
```

### Inflation Calculations
```clarity
(contract-call? .Inflation-Protected-Village-Savings get-current-inflation-rate)
(contract-call? .Inflation-Protected-Village-Savings calculate-projected-balance u1000000 u1000)
```

## 💡 How It Works

1. **Inflation Calculation**: Uses time-elapsed since deposit × inflation rate to calculate protection
2. **Default Rate**: 3% annual inflation (300 basis points), adjustable by contract owner
3. **Block-based**: Calculations use Stacks block height for precise timing
4. **Automatic Protection**: Withdrawals automatically include inflation adjustments

## 🔒 Security Features

- ✅ Owner-only inflation rate updates
- ✅ Member-only access controls
- ✅ Balance validation before withdrawals
- ✅ Active status checks for groups and members
- ✅ Automatic STX transfer handling

## 🧪 Testing

```bash
npm install
npm test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `clarinet check` to verify syntax
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🌍 Impact

Empowering rural communities with inflation-resistant savings tools, bringing financial stability through blockchain innovation.
