// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Membership {
    struct Post {
        uint id;
        address author;
        string content;
        string[] comments;
    }

    mapping(address => bool) public members;
    mapping(address => string) public profiles;
    Post[] public posts;
    uint public nextPostId;

    event MembershipMinted(address indexed member);
    event ProfileUpdated(address indexed member, string newProfile);
    event PostCreated(uint indexed postId, address indexed author, string content);
    event CommentAdded(uint indexed postId, string comment);

    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }

    function mint() external {
        require(!members[msg.sender], "Already a member");
        members[msg.sender] = true;
        emit MembershipMinted(msg.sender);
    }

    function updateProfile(string calldata newProfile) external onlyMember {
        profiles[msg.sender] = newProfile;
        emit ProfileUpdated(msg.sender, newProfile);
    }

    function createPost(string calldata content) external onlyMember {
        posts.push(Post({
            id: nextPostId,
            author: msg.sender,
            content: content,
            comments: new string[](0)
        }));
        emit PostCreated(nextPostId, msg.sender, content);
        nextPostId++;
    }

    function addComment(uint postId, string calldata comment) external onlyMember {
        require(postId < posts.length, "Post does not exist");
        posts[postId].comments.push(comment);
        emit CommentAdded(postId, comment);
    }

    function getPosts() external view returns (Post[] memory) {
        return posts;
    }
}