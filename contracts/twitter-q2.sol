// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Twitter {
    // Tweet structure
    struct Tweet {
        uint tweetId;
        address author;
        string content;
        uint createdAt;
    }

    // Message structure for user DMs
    struct Message {
        uint messageId;
        string content;
        address from;
        address to;
        uint createdAt;
    }

    // User structure
    struct User {
        address wallet;
        string name;
        uint[] userTweets;
        address[] following;
        address[] followers;
        mapping(address => Message[]) conversations;
    }

    // Mappings for user accounts and tweets
    mapping(address => User) public users;
    mapping(uint => Tweet) public tweets;

    // Like and retweet tracking
    mapping(uint => uint) public likeCount;
    mapping(uint => mapping(address => bool)) public likedBy;
    mapping(uint => uint) public retweetCount;
    mapping(uint => mapping(address => bool)) public retweetedBy;
    mapping(uint => uint[]) public retweetSources;

    // Events
    event TweetLiked(uint indexed tweetId, address indexed user);
    event TweetUnliked(uint indexed tweetId, address indexed user);
    event TweetRetweeted(uint indexed originalTweetId, uint indexed newTweetId, address indexed user);

    // Tweet and message ID counters
    uint256 public nextTweetId;
    uint256 public nextMessageId;

    // Register a user account
    function registerAccount(string calldata _name) external {
        bytes memory tempEmptyStringTest = bytes(_name);
        require(tempEmptyStringTest.length != 0, "Name cannot be an empty string");

        User storage user = users[msg.sender];
        user.wallet = msg.sender;
        user.name = _name;
    }

    // Post a tweet
    function postTweet(string calldata _content) external accountExists(msg.sender) {
        uint256 id = nextTweetId++;
        tweets[id] = Tweet({
            tweetId: id,
            author: msg.sender,
            content: _content,
            createdAt: block.timestamp
        });

        users[msg.sender].userTweets.push(id);
    }

    // Get all tweets by a user
    function readTweets(address _user) view external returns(Tweet[] memory) {
        User storage user = users[_user];
        uint[] storage userTweetIds = user.userTweets;

        Tweet[] memory userTweets = new Tweet[](userTweetIds.length);
        for (uint i = 0; i < userTweetIds.length; i++) {
            userTweets[i] = tweets[userTweetIds[i]];
        }
        return userTweets;
    }

    // Modifier to ensure user exists
    modifier accountExists(address _user) {
        require(
            bytes(users[_user].name).length != 0, 
            "This wallet does not belong to any account"
        );
        _;
    }

    // Follow another user
    function followUser(address _user) external accountExists(msg.sender) {
        require(_user != msg.sender, "Cannot follow yourself");
        require(users[_user].wallet != address(0), "User doesn't exist");
        
        // Check not already following
        address[] storage following = users[msg.sender].following;
        for (uint i = 0; i < following.length; i++) {
            if (following[i] == _user) revert("Already following");
        }

        users[msg.sender].following.push(_user);
        users[_user].followers.push(msg.sender);
    }

    // Get users the caller is following
    function getFollowing() external view returns(address[] memory) {
        return users[msg.sender].following;
    }

    // Get followers of the caller
    function getFollowers() external view returns(address[] memory) {
        return users[msg.sender].followers;
    }

    // Get personalized tweet feed (followed users only)
    function getTweetFeed() view external returns(Tweet[] memory) {
        address[] storage following = users[msg.sender].following;
        
        // Count total tweets
        uint totalTweets;
        for (uint i = 0; i < following.length; i++) {
            totalTweets += users[following[i]].userTweets.length;
        }
        
        // Collect tweets
        Tweet[] memory feed = new Tweet[](totalTweets);
        uint index;
        
        for (uint i = 0; i < following.length; i++) {
            uint[] storage tweetIds = users[following[i]].userTweets;
            for (uint j = 0; j < tweetIds.length; j++) {
                feed[index] = tweets[tweetIds[j]];
                index++;
            }
        }
        
        // Sort by timestamp (newest first)
        for (uint i = 0; i < totalTweets; i++) {
            for (uint j = i+1; j < totalTweets; j++) {
                if (feed[i].createdAt < feed[j].createdAt) {
                    Tweet memory temp = feed[i];
                    feed[i] = feed[j];
                    feed[j] = temp;
                }
            }
        }
        
        return feed;
    }

    // Send a message to another user
    function sendMessage(address _recipient, string calldata _content) 
        external 
        accountExists(msg.sender) 
    {
        require(_recipient != msg.sender, "Cannot message yourself");
        require(users[_recipient].wallet != address(0), "Recipient not registered");

        uint256 id = nextMessageId++;
        Message memory message = Message({
            messageId: id,
            content: _content,
            from: msg.sender,
            to: _recipient,
            createdAt: block.timestamp
        });

        users[msg.sender].conversations[_recipient].push(message);
        users[_recipient].conversations[msg.sender].push(message);
    }

    // Retrieve message thread with another user
    function getConversationWithUser(address _partner) 
        external 
        view 
        returns(Message[] memory) 
    {
        return users[msg.sender].conversations[_partner];
    }

    // Unfollow a user
    function unfolowUser(address _user) external accountExists(msg.sender) {
        // Remove from sender's following
        address[] storage following = users[msg.sender].following;
        for (uint i = 0; i < following.length; i++) {
            if (following[i] == _user) {
                following[i] = following[following.length - 1];
                following.pop();
                break;
            }
        }
        
        // Remove from target's followers
        address[] storage followers = users[_user].followers;
        for (uint i = 0; i < followers.length; i++) {
            if (followers[i] == msg.sender) {
                followers[i] = followers[followers.length - 1];
                followers.pop();
                break;
            }
        }
    }

    // Like a tweet
    function likeTweet(uint _tweetId) external accountExists(msg.sender) {
        require(_tweetId < nextTweetId, "Invalid tweet ID");
        require(!likedBy[_tweetId][msg.sender], "Already liked");

        likedBy[_tweetId][msg.sender] = true;
        likeCount[_tweetId]++;
        emit TweetLiked(_tweetId, msg.sender);
    }

    // Unlike a tweet
    function unlikeTweet(uint _tweetId) external {
        require(likedBy[_tweetId][msg.sender], "Not liked");

        likedBy[_tweetId][msg.sender] = false;
        likeCount[_tweetId]--;
        emit TweetUnliked(_tweetId, msg.sender);
    }

    // Retweet a tweet
    function retweet(uint _originalTweetId) external accountExists(msg.sender) {
        require(_originalTweetId < nextTweetId, "Invalid tweet ID");
        require(!retweetedBy[_originalTweetId][msg.sender], "Already retweeted");

        uint newTweetId = nextTweetId++;
        tweets[newTweetId] = Tweet({
            tweetId: newTweetId,
            author: msg.sender,
            content: "",
            createdAt: block.timestamp
        });

        retweetedBy[_originalTweetId][msg.sender] = true;
        retweetCount[_originalTweetId]++;
        retweetSources[newTweetId].push(_originalTweetId);

        users[msg.sender].userTweets.push(newTweetId);
        emit TweetRetweeted(_originalTweetId, newTweetId, msg.sender);
    }

    // Get number of likes on a tweet
    function getLikeCount(uint _tweetId) public view returns (uint) {
        return likeCount[_tweetId];
    }

    // Get number of retweets of a tweet
    function getRetweetCount(uint _tweetId) public view returns (uint) {
        return retweetCount[_tweetId];
    }

    // Get source tweets of a retweet
    function getRetweetSources(uint _tweetId) public view returns (uint[] memory) {
        return retweetSources[_tweetId];
    }
}