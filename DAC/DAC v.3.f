pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// --- Core Components ---

contract DAOToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
}

contract MembershipNFT is ERC721Enumerable {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
}

// --- DAO Contract ---

contract DAO is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Canceled }

    struct Proposal {
        string description;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 quorum; // Minimum votes required for the proposal to be valid
        ProposalState state;
        address proposer;
        bytes32 proposalHash; // For off-chain voting and dispute resolution
    }

    struct InvestmentProposal {
        string description;
        address beneficiary; // Recipient of funds
        uint256 amount;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
    }

    DAOToken public immutable token;
    MembershipNFT public immutable membershipNFT;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => InvestmentProposal) public investmentProposals;
    mapping(uint256 => address[]) public proposalVoters; // Track voters for accountability

    uint256 public constant QUORUM_PERCENTAGE = 50; // 50% quorum as an example
    uint256 public proposalCount;
    uint256 public investmentProposalCount;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 votingStart, uint256 votingEnd);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState state);
    event InvestmentProposalCreated(uint256 indexed proposalId, address beneficiary, uint256 amount);

    constructor(address _tokenAddress, address _membershipNFTAddress) {
        token = DAOToken(_tokenAddress);
        membershipNFT = MembershipNFT(_membershipNFTAddress);
    }

    // --- Proposal Functions ---

    function createProposal(string memory _description, uint256 _votingPeriod) public whenNotPaused {
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can create proposals");

        proposalCount++;
        bytes32 _proposalHash = keccak256(abi.encodePacked(_description, _votingPeriod)); 
        proposals[proposalCount] = Proposal({
            description: _description,
            votingStart: block.timestamp,
            votingEnd: block.timestamp + _votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            quorum: (token.totalSupply() * QUORUM_PERCENTAGE) / 100, 
            state: ProposalState.Pending,
            proposer: msg.sender,
            proposalHash: _proposalHash
        });

        emit ProposalCreated(proposalCount, _description, block.timestamp, block.timestamp + _votingPeriod);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote"); 
        require(!hasVoted(_proposalId, msg.sender), "Already voted on this proposal"); 

        if (_support) {
            proposals[_proposalId].yesVotes += 1; 
        } else {
            proposals[_proposalId].noVotes += 1;
        }

        proposalVoters[_proposalId].push(msg.sender); 
        emit VoteCast(msg.sender, _proposalId, _support);
    }

    function finalizeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(block.timestamp > proposals[_proposalId].votingEnd, "Voting has not ended");

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.yesVotes >= proposal.quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
        } else {
            proposal.state = ProposalState.Rejected;
        }

        emit ProposalFinalized(_proposalId, proposal.state);
    }

    // --- Investment Proposal Functions ---

    function createInvestmentProposal(
        string memory _description, 
        address _beneficiary, 
        uint256 _amount, 
        uint256 _votingPeriod
    ) public whenNotPaused {
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can create investment proposals"); 

        investmentProposalCount++;
        investmentProposals[investmentProposalCount] = InvestmentProposal({
            description: _description,
            beneficiary: _beneficiary,
            amount: _amount,
            votingStart: block.timestamp,
            votingEnd: block.timestamp + _votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Pending
        });
    }

    function voteOnInvestmentProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId > 0 && _proposalId <= investmentProposalCount, "Invalid proposal ID");
        require(investmentProposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote"); 
        require(!hasVotedOnInvestmentProposal(_proposalId, msg.sender), "Already voted on this proposal"); 

        if (_support) {
            investmentProposals[_proposalId].yesVotes += 1; 
        } else {
            investmentProposals[_proposalId].noVotes += 1;
        }

        // Track voters for investment proposals (similar to proposalVoters)
    }

    function finalizeInvestmentProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= investmentProposalCount, "Invalid proposal ID");
        require(investmentProposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(block.timestamp > investmentProposals[_proposalId].votingEnd, "Voting has not ended");

        InvestmentProposal storage proposal = investmentProposals[_proposalId];

        if (proposal.yesVotes >= proposal.quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
            // Execute approved investment (e.g., transfer funds to beneficiary)
            // This requires a treasury mechanism and proper security measures
        } else {
            proposal.state = ProposalState.Rejected;
        }
    }

    // --- Helper Functions ---

    function hasVoted(uint256 _proposalId, address _voter) internal view returns (bool) {
        for (uint256 i = 0; i < proposalVoters[_proposalId].length; i++) {
            if (proposalVoters[_proposalId][i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function hasVotedOnInvestmentProposal(uint256 _proposalId, address _voter) internal view returns (bool) {
        // Implement similar logic to hasVoted() for investment proposals
    }

    // --- Pause/Unpause Functionality ---
    // Allows the DAO to pause all operations in case of emergencies or for maintenance.
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Treasury Management, Fair Use Enforcement, etc. ---
    // These sections require further development and should be implemented with careful consideration.