const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Twitter Project Extended Tests", () => {
  let Twitter, twitter, addr1, addr2, addr3, addr4;

  beforeEach(async () => {
    Twitter = await ethers.getContractFactory("Twitter");
    twitter = await Twitter.deploy();
    [addr1, addr2, addr3, addr4] = await ethers.getSigners();

    // Register accounts
    await twitter.connect(addr1).registerAccount("Alice");
    await twitter.connect(addr2).registerAccount("Bob");
    await twitter.connect(addr3).registerAccount("Charlie");

    // Post tweets
    await twitter.connect(addr1).postTweet("Learning about Web3 is fun!");
    await twitter
      .connect(addr2)
      .postTweet(
        "I really like Data Science, but I guess Web3 development is kind of cool too"
      );
    await twitter.connect(addr3).postTweet("Apples are so tasty");
    await twitter
      .connect(addr2)
      .postTweet("Theres so much to cover in machine learning");
    await twitter
      .connect(addr3)
      .postTweet("Apple juice is basically sugar water");
    await twitter
      .connect(addr3)
      .postTweet("Green apples are better than red ones");

    // Setup follows
    await twitter.connect(addr1).followUser(addr2.address);
    await twitter.connect(addr1).followUser(addr3.address);
    await twitter.connect(addr2).followUser(addr3.address);
  });

  describe("Core Functionality", () => {
    it("Should register accounts", async () => {
      const alice = await twitter.users(addr1.address);
      expect(alice.name).to.equal("Alice");
      expect(alice.wallet).to.equal(addr1.address);
    });

    it("Should post and retrieve tweets", async () => {
      const aliceTweets = await twitter.readTweets(addr1.address);
      expect(aliceTweets.length).to.equal(1);
      expect(aliceTweets[0].content).to.equal("Learning about Web3 is fun!");
    });
  });

  describe("Follow System", () => {
    it("Should follow users", async () => {
      const following = await twitter.connect(addr1).getFollowing();
      expect(following).to.include(addr2.address);
      expect(following).to.include(addr3.address);
    });

    it("Should get followers", async () => {
      const followers = await twitter.connect(addr3).getFollowers();
      expect(followers).to.include(addr1.address);
      expect(followers).to.include(addr2.address);
    });

    it("Should unfollow users", async () => {
      // Unfollow addr3
      await twitter.connect(addr1).unfolowUser(addr3.address);
      
      // Verify following list
      const following = await twitter.connect(addr1).getFollowing();
      expect(following).to.not.include(addr3.address);
      expect(following).to.include(addr2.address);
      
      // Verify followers list
      const charlieFollowers = await twitter.connect(addr3).getFollowers();
      expect(charlieFollowers).to.not.include(addr1.address);
      expect(charlieFollowers).to.include(addr2.address);
    });

    it("Should prevent self-following", async () => {
      await expect(
        twitter.connect(addr1).followUser(addr1.address)
      ).to.be.revertedWith("Cannot follow yourself");
    });
  });

  describe("Tweet Feed", () => {
    it("Should get personalized tweet feed", async () => {
      const feed = await twitter.connect(addr1).getTweetFeed();
      
      // Should see tweets from followed users (addr2 has 2, addr3 has 3 → 5 total)
      expect(feed.length).to.equal(5);
      
      // Verify authors
      const authors = feed.map(t => t.author);
      expect(authors).to.include(addr2.address);
      expect(authors).to.include(addr3.address);
      expect(authors).to.not.include(addr1.address);
      
      // Verify chronological order (newest first)
      for (let i = 0; i < feed.length - 1; i++) {
        expect(feed[i].createdAt).to.be.greaterThanOrEqual(feed[i+1].createdAt);
      }
    });

    it("Should return empty feed for new user", async () => {
      // Register but don't follow anyone
      await twitter.connect(addr4).registerAccount("Dana");
      const feed = await twitter.connect(addr4).getTweetFeed();
      expect(feed.length).to.equal(0);
    });
  });

  describe("Messaging System", () => {
    beforeEach(async () => {
      await twitter
        .connect(addr1)
        .sendMessage(
          addr2.address,
          "Hi Bob! Wanna get lunch and catch up soon?"
        );
      await twitter
        .connect(addr2)
        .sendMessage(addr1.address, "Hey Alice, that sounds good!");
    });

    it("Should send and retrieve messages", async () => {
      const convo = await twitter
        .connect(addr1)
        .getConversationWithUser(addr2.address);
        
      expect(convo.length).to.equal(2);
      expect(convo[0].content).to.equal("Hi Bob! Wanna get lunch and catch up soon?");
      expect(convo[1].content).to.equal("Hey Alice, that sounds good!");
    });

    it("Should prevent self-messaging", async () => {
      await expect(
        twitter.connect(addr1).sendMessage(addr1.address, "Hello me")
      ).to.be.revertedWith("Cannot message yourself");
    });
  });

  describe("Engagement Features", () => {
    const TWEET_ID = 0; // Alice's first tweet

    it("Should like and unlike tweets", async () => {
      // Initial state
      expect(await twitter.getLikeCount(TWEET_ID)).to.equal(0);
      
      // Like tweet
      await twitter.connect(addr2).likeTweet(TWEET_ID);
      expect(await twitter.getLikeCount(TWEET_ID)).to.equal(1);
      expect(await twitter.likedBy(TWEET_ID, addr2.address)).to.be.true;
      
      // Second like
      await twitter.connect(addr3).likeTweet(TWEET_ID);
      expect(await twitter.getLikeCount(TWEET_ID)).to.equal(2);
      
      // Unlike
      await twitter.connect(addr2).unlikeTweet(TWEET_ID);
      expect(await twitter.getLikeCount(TWEET_ID)).to.equal(1);
      expect(await twitter.likedBy(TWEET_ID, addr2.address)).to.be.false;
    });

    it("Should prevent double liking", async () => {
      await twitter.connect(addr2).likeTweet(TWEET_ID);
      await expect(twitter.connect(addr2).likeTweet(TWEET_ID))
        .to.be.revertedWith("Already liked");
    });

    it("Should retweet", async () => {
      const initialCount = await twitter.getRetweetCount(TWEET_ID);
      await twitter.connect(addr3).retweet(TWEET_ID);
      
      // Verify retweet count
      expect(await twitter.getRetweetCount(TWEET_ID)).to.equal(initialCount.toNumber() + 1);
      
      // Verify new tweet
      const newTweetId = (await twitter.nextTweetId()).toNumber() - 1;
      const retweet = await twitter.tweets(newTweetId);
      
      expect(retweet.author).to.equal(addr3.address);
      
      // Verify retweet sources
      const sources = await twitter.getRetweetSources(newTweetId);
      expect(sources[0]).to.equal(TWEET_ID);
    });
  });

  describe("Edge Cases", () => {
    it("Should prevent unregistered actions", async () => {
      await expect(
        twitter.connect(addr4).postTweet("I'm not registered")
      ).to.be.revertedWith("This wallet does not belong to any account");
      
      await expect(
        twitter.connect(addr4).followUser(addr1.address)
      ).to.be.reverted;
    });

    it("Should prevent invalid tweet operations", async () => {
      await expect(twitter.connect(addr1).likeTweet(999))
        .to.be.revertedWith("Invalid tweet ID");
      
      await expect(twitter.connect(addr1).retweet(999))
        .to.be.revertedWith("Invalid tweet ID");
    });
  });
});