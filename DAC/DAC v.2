pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAOToken is ERC20, Ownable {
    constructor() ERC20("DAO Token", "DAO") {
        _mint(msg.sender, 1000000); // Initial token distribution for governance 
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract DAO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum ProposalState { Pending, Active, Passed, Rejected }

    struct Proposal {
        string description;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 quorum; // Minimum votes required for a proposal to be valid
        ProposalState state;
    }

    DAOToken public token;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public quorumPercentage; // Percentage of total supply required for quorum

    constructor(address _tokenAddress) {
        token = DAOToken(_tokenAddress);
        quorumPercentage = 50; // Set initial quorum percentage to 50%
    }

    function createProposal(string memory _description, uint256 _votingPeriod) public onlyOwner {
        require(_votingPeriod > 0, "Voting period must be greater than 0");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            votingStart: block.timestamp,
            votingEnd: block.timestamp + _votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            quorum: (token.totalSupply() * quorumPercentage) / 100, 
            state: ProposalState.Pending
        });
    }

    function vote(uint256 _proposalId, bool _support) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(token.balanceOf(msg.sender) > 0, "Must hold tokens to vote");

        if (_support) {
            proposals[_proposalId].yesVotes += token.balanceOf(msg.sender);
        } else {
            proposals[_proposalId].noVotes += token.balanceOf(msg.sender);
        }
    }

    function finalizeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(block.timestamp > proposals[_proposalId].votingEnd, "Voting has not ended");

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.yesVotes + proposal.noVotes >= proposal.quorum) {
            if (proposal.yesVotes > proposal.noVotes) {
                proposal.state = ProposalState.Passed;
                // Execute approved proposal (e.g., fund a project, change parameters)
                // This section requires specific logic for each proposal type
            } else {
                proposal.state = ProposalState.Rejected;
            }
        } else {
            proposal.state = ProposalState.Rejected; // Proposal failed to reach quorum
        }
    }

    // Function to change quorum percentage (requires governance approval)
    function setQuorumPercentage(uint256 _newQuorumPercentage) public onlyOwner {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "Invalid quorum percentage");
        quorumPercentage = _newQuorumPercentage;
    }
}