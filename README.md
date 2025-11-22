# 🤖 AI Model Licensing NFTs

> **Revolutionizing AI model ownership, licensing, and monetization through blockchain technology** 🚀

## 📋 Overview

This smart contract enables AI researchers and developers to mint their trained models as NFTs, representing ownership and licensing rights. The platform facilitates fair monetization through automated royalty distribution and flexible licensing terms.

## ✨ Features

- 🏭 **Model Minting**: Convert AI models into tradeable NFTs
- 📄 **Flexible Licensing**: Support for inference-only, retraining, and commercial use rights  
- 💰 **Automated Royalties**: Fair compensation through automatic royalty distribution
- ⏱️ **Time-based Rentals**: Rent models for specific durations
- 📊 **Usage Tracking**: Monitor model usage and enforce limits
- 🔄 **License Extensions**: Extend rental periods seamlessly
- 💎 **Ownership Transfer**: Trade model ownership rights

## 🛠️ Contract Functions

### Public Functions

#### `mint-ai-model`
Mint a new AI model as an NFT with licensing terms.
```clarity
(mint-ai-model 
  "GPT-4-Clone" 
  "Advanced language model for text generation" 
  "0x1234567890abcdef" 
  u500 
  u1000000 
  u7 
  true 
  false 
  true 
  u1000 
  u100)
```

#### `rent-license`
Rent a license to use an AI model.
```clarity
(rent-license u1 u30)
```

#### `use-model`
Record usage of a licensed model (increments usage count).
```clarity
(use-model u1)
```

#### `transfer-model`
Transfer model ownership between principals.
```clarity
(transfer-model u1 'SP123... 'SP456...)
```

#### `extend-license`
Extend an existing license duration.
```clarity
(extend-license u1 u15)
```

#### `withdraw-royalties`
Withdraw accumulated royalties for model creators.
```clarity
(withdraw-royalties)
```

#### `update-base-price`
Update the base rental price for a model (owner only).
```clarity
(update-base-price u1 u2000000)
```

### Read-Only Functions

#### `get-model-info`
Retrieve metadata for a specific model.

#### `get-license-terms`
Get licensing terms and restrictions for a model.

#### `get-active-license`
Check active license details for a user and model.

#### `get-owner`
Get the current owner of a model NFT.

#### `is-license-active`
Check if a license is currently active and valid.

#### `get-usage-count`
Get current usage count for a specific license.

#### `get-royalty-balance`
Check accumulated royalty balance for a creator.

## 📊 Data Structures

### Model Metadata
- **name**: Model identifier (64 chars)
- **description**: Model description (256 chars)
- **model-hash**: Cryptographic hash of model
- **creator**: Original model creator
- **royalty-percentage**: Royalty rate (basis points)
- **base-price**: Base rental price per block
- **usage-types**: Supported usage categories

### License Terms
- **inference-only**: Restrict to inference only
- **retraining-allowed**: Allow model fine-tuning
- **commercial-use**: Enable commercial applications
- **duration-blocks**: Default license duration
- **max-inferences**: Maximum usage limit

## 💡 Usage Examples

### For Model Creators 👩‍💻

1. **Mint Your Model**:
   ```clarity
   ;; Mint a computer vision model with 5% royalties
   (mint-ai-model 
     "ResNet-Vision-v2" 
     "Advanced computer vision model for image classification" 
     "0xabcdef1234567890" 
     u500 
     u500000 
     u3 
     true 
     false 
     true 
     u2000 
     u1000)
   ```

2. **Withdraw Earnings**:
   ```clarity
   (withdraw-royalties)
   ```

### For Model Users 🧑‍💼

1. **Rent a License**:
   ```clarity
   ;; Rent model #1 for 30 blocks
   (rent-license u1 u30)
   ```

2. **Use the Model**:
   ```clarity
   ;; Record model usage (increments counter)
   (use-model u1)
   ```

3. **Extend License**:
   ```clarity
   ;; Add 15 more blocks to existing license
   (extend-license u1 u15)
   ```

## 🏗️ Development Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) CLI
- Node.js and npm
- Stacks Wallet

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd AI-Model-Licensing-NFTs

# Install dependencies
npm install

# Run tests
npm test

# Check contract syntax
clarinet check
```

### Local Development
```bash
# Start local development network
clarinet integrate

# Deploy to testnet
clarinet deployments generate --testnet
clarinet deployments apply -p <plan-file>
```

## 🔧 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `ERR_NOT_AUTHORIZED` | Insufficient permissions |
| u101 | `ERR_NOT_FOUND` | Resource not found |
| u102 | `ERR_ALREADY_EXISTS` | Resource already exists |
| u103 | `ERR_INVALID_PRICE` | Invalid price parameter |
| u104 | `ERR_INSUFFICIENT_FUNDS` | Not enough STX balance |
| u105 | `ERR_LICENSE_EXPIRED` | License has expired |
| u106 | `ERR_INVALID_USAGE_TYPE` | Usage limit exceeded |
| u107 | `ERR_ROYALTY_TOO_HIGH` | Royalty exceeds maximum |

## 🌟 Benefits

### For AI Researchers 🔬
- **Monetize Research**: Convert models into revenue-generating assets
- **Retain Control**: Maintain ownership while enabling access
- **Fair Compensation**: Automatic royalty distribution
- **Usage Analytics**: Track how models are being used

### For Businesses 🏢
- **Access Premium Models**: Rent state-of-the-art AI without huge upfront costs
- **Flexible Terms**: Choose licensing that fits your use case
- **Transparent Pricing**: Clear, blockchain-verified pricing
- **Scalable Usage**: Pay only for what you use

### For the Ecosystem 🌍
- **Open Innovation**: Democratized access to AI technology
- **Standard Framework**: Unified licensing protocol
- **Trust & Verification**: Blockchain-backed authenticity
- **Economic Incentives**: Sustainable AI development funding

## 🛡️ Security Considerations

- All financial operations use STX transfers with proper error handling
- License validation prevents unauthorized usage
- Ownership verification for administrative functions
- Usage limits enforce licensing terms
- Royalty calculations prevent overflow attacks

## 🚀 Future Enhancements

- Multi-token royalty support
- Advanced licensing templates
- Model performance benchmarking
- Integration with AI training platforms
- Decentralized model hosting

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

---

**Built with ❤️ for the future of AI development** 🌟

# AI Model Licensing NFTs

