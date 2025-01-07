pragma solidity ^0.8.0;

contract DAO {

    // Define a struct to represent a proposal
    struct Proposal {
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 yesVotes;
        uint256 noVotes;
    }

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Array to store proposal IDs
    uint256[] public proposalIds;

    // Event emitted when a new proposal is created
    event ProposalCreated(
        uint256 proposalId,
        string description,
        uint256 voteStart,
        uint256 voteEnd
    );

    // Event emitted when a vote is cast
    event VoteCast(address voter, uint256 proposalId, bool support);

    // Function to create a new proposal
    function createProposal(string memory _description, uint256 _voteStart, uint256 _voteEnd) public {
        require(_voteEnd > _voteStart, "Vote end time must be after start time");

        uint256 proposalId = proposalIds.length;
        proposals[proposalId] = Proposal({
            description: _description,
            voteStart: _voteStart,
            voteEnd: _voteEnd,
            yesVotes: 0,
            noVotes: 0
        });

        proposalIds.push(proposalId);

        emit ProposalCreated(proposalId, _description, _voteStart, _voteEnd);
    }

    // Function to cast a vote on a proposal
    function vote(uint256 _proposalId, bool _support) public {
        require(block.timestamp >= proposals[_proposalId].voteStart, "Voting has not started");
        require(block.timestamp <= proposals[_proposalId].voteEnd, "Voting has ended");

        if (_support) {
            proposals[_proposalId].yesVotes += 1;
        } else {
            proposals[_proposalId].noVotes += 1;
        }

        emit VoteCast(msg.sender, _proposalId, _support);
    }

    // Function to get the result of a proposal
    function getProposalResult(uint256 _proposalId) public view returns (bool) {
        require(block.timestamp > proposals[_proposalId].voteEnd, "Voting has not ended");

        return proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes;
    }
}