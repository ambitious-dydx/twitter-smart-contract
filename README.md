# 🐦 Decentralized Twitter on Ethereum

[![Solidity Version](https://img.shields.io/badge/Solidity-0.8.9-blue)](https://soliditylang.org)
[![Built with Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-yellow)](https://hardhat.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A fully functional Twitter clone implemented as an Ethereum smart contract. This decentralized application features user profiles, tweet posting, follow systems, direct messaging, and engagement features - all on-chain.

## 🌟 Features

- **User Profiles**
  - Register accounts with unique names
  - On-chain profile storage
- **Tweet System**
  - Post text tweets with timestamps
  - View user-specific tweet history
- **Social Graph**
  - Follow/unfollow other users
  - Get followers/following lists
- **Personalized Feed**
  - View tweets from followed accounts
  - Chronologically sorted (newest first)
- **Direct Messaging**
  - Send private messages
  - Full conversation history
- **Engagement Features**
  - Like/unlike tweets
  - Retweet functionality
  - Like/retweet counters

## 📦 Contract Structure

```solidity
contract Twitter {
    struct Tweet {
        uint tweetId;
        address author;
        string content;
        uint createdAt;
    }
    
    struct Message {
        uint messageId;
        string content;
        address from;
        address to;
        uint createdAt;
    }
    
    // Core Functions
    function registerAccount(string calldata _name) external;
    function postTweet(string calldata _content) external;
    function followUser(address _user) external;
    function sendMessage(address _recipient, string calldata _content) external;
    
    // Engagement
    function likeTweet(uint _tweetId) external;
    function retweet(uint _originalTweetId) external;
    
    // View Functions
    function getTweetFeed() external view returns(Tweet[] memory);
    function getConversationWithUser(address _partner) external view returns(Message[] memory);
}
```
## 🚀 Getting Started
Prerequisites
Node.js v16+

npm or yarn

Git

## Installation
1. Clone the repository:
```batch
git clone https://github.com/<your-username>/twitter-smart-contract.git
cd twitter-smart-contract
```
2. Install dependencies:
```bash
npm install
```
3. Compile the contract:
```bash
npx hardhat compile
```
## Testing
Run the comprehensive test suite:
```bash
npx hardhat test
```
## Sample output:
```text
Twitter Project Extended Tests
  Core Functionality
    ✓ Should register accounts
    ✓ Should post and retrieve tweets
  Follow System
    ✓ Should follow users
    ✓ Should get followers
    ✓ Should unfollow users
  Tweet Feed
    ✓ Should get personalized tweet feed (50ms)
    ✓ Should return empty feed for new user
  Messaging System
    ✓ Should send and retrieve messages
  Engagement Features
    ✓ Should like and unlike tweets
    ✓ Should prevent double liking
    ✓ Should retweet
  Edge Cases
    ✓ Should prevent unregistered actions
    ✓ Should prevent invalid tweet operations

  12 passing (1s)
```
## 📡 Deployment
Local Network
1. Start a local node:
```bash
npx hardhat node
```
2. In a separate terminal, deploy:
```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Testnet (Goerli)
1. Set up environment variables in .env:
```bash
GOERLI_URL=https://eth-goerli.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=YOUR_PRIVATE_KEY
```
2. Deploy:
```bash
npx hardhat run scripts/deploy.js --network goerli
```
## 💻 Usage
Interacting with Contract
After deployment, interact using Hardhat console:
```bash
npx hardhat console --network localhost
> const Twitter = await ethers.getContractFactory("Twitter")
> const twitter = await Twitter.attach("<DEPLOYED_ADDRESS>")
> await twitter.registerAccount("Alice")
> await twitter.postTweet("Hello Web3!")
```

## Frontend Integration
Connect to the contract using ethers.js:
```javascript
import { ethers } from "ethers";

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const contract = new ethers.Contract(
  "0xCONTRACT_ADDRESS",
  contractABI,
  signer
);

// Post a tweet
await contract.postTweet("Decentralized tweets are awesome!");
```

## 📊 Project Structure
```text
twitter-smart-contract/
├── contracts/               # All smart contracts
│   └── Twitter.sol          # Main contract
├── test/                    # Test files
│   └── twitter.test.js      # Main test suite
├── node_modules/            # Dependencies (auto-generated)
├── .env                     # Environment variables
├── .gitignore               # Files to ignore in Git
├── hardhat.config.js        # Hardhat configuration
├── package.json             # Project metadata and dependencies
└── README.md                # Project documentation
```

## 🤝 Contributing
1. Fork the project
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit your changes (git commit -m 'Add some amazing feature')
4. Push to the branch (git push origin feature/AmazingFeature)
5. Open a pull request

## 📜 License
Distributed under the MIT License. See LICENSE for more information.

## 📬 Contact
Ambitious - @PleaseeThink - ambitiousdydx@gmail.com
Project Link: https://github.com/ambitious-dydx/twitter-smart-contract



