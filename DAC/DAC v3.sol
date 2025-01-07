pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract DAOToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
}

contract MembershipNFT is ERC721Enumerable {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to) external {  // Simplified minting for demonstration
        _mint(_to, totalSupply() + 1);
    }
}

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
        uint256 quorum;
        ProposalState state;
        address proposer;
        bytes32 proposalHash;
    }

    struct InvestmentProposal {
        string description;
        address beneficiary;
        uint256 amount;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
    }

    DAOToken public immutable token;
    MembershipNFT public immutable membershipNFT;
    IERC20 public treasuryToken; // Token used for the treasury

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => InvestmentProposal) public investmentProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVoters;
    mapping(uint256 => mapping(address => bool)) public investmentProposalVoters;


    uint256 public constant QUORUM_PERCENTAGE = 50;
    uint256 public proposalCount;
    uint256 public investmentProposalCount;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 votingStart, uint256 votingEnd);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState state);
    event InvestmentProposalCreated(uint256 indexed proposalId, address beneficiary, uint256 amount);
    event InvestmentProposalExecuted(uint256 indexed proposalId, address beneficiary, uint256 amount);


    constructor(address _tokenAddress, address _membershipNFTAddress, address _treasuryToken) {
        token = DAOToken(_tokenAddress);
        membershipNFT = MembershipNFT(_membershipNFTAddress);
        treasuryToken = IERC20(_treasuryToken);
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
            state: ProposalState.Active, // Directly set to Active
            proposer: msg.sender,
            proposalHash: _proposalHash
        });

        emit ProposalCreated(proposalCount, _description, block.timestamp, block.timestamp + _votingPeriod);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused nonReentrant {
        _voteOnProposal(_proposalId, _support);
    }


    function finalizeProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Voting not active or already finalized");
        require(block.timestamp > proposal.votingEnd, "Voting has not ended");

        if (proposal.yesVotes >= proposal.quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
        } else {
            proposal.state = ProposalState.Rejected;
        }

        emit ProposalFinalized(_proposalId, proposal.state);
    }



    // --- Investment Proposal Functions ---

    function createInvestmentProposal(string memory _description, address _beneficiary, uint256 _amount, uint256 _votingPeriod)
        public
        whenNotPaused
    {
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
            state: ProposalState.Active // Directly to Active
        });

        emit InvestmentProposalCreated(investmentProposalCount, _beneficiary, _amount);
    }


    function voteOnInvestmentProposal(uint256 _proposalId, bool _support) public whenNotPaused nonReentrant {
       _voteOnInvestmentProposal(_proposalId, _support);

    }

    function finalizeInvestmentProposal(uint256 _proposalId) public onlyOwner {
        require(_proposalId > 0 && _proposalId <= investmentProposalCount, "Invalid proposal ID");
        InvestmentProposal storage proposal = investmentProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Voting not active or already finalized");
        require(block.timestamp > proposal.votingEnd, "Voting has not ended");

        if (proposal.yesVotes >= proposal.quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
            // Execute investment
            treasuryToken.safeTransfer(proposal.beneficiary, proposal.amount);
            emit InvestmentProposalExecuted(_proposalId, proposal.beneficiary, proposal.amount);
        } else {
            proposal.state = ProposalState.Rejected;
        }
    }


    // --- Helper Functions ---
    function _voteOnProposal(uint256 _proposalId, bool _support) internal {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote");
        require(!proposalVoters[_proposalId][msg.sender], "Already voted on this proposal");

        if (_support) {
            proposals[_proposalId].yesVotes += 1;
        } else {
            proposals[_proposalId].noVotes += 1;
        }

        proposalVoters[_proposalId][msg.sender] = true;
        emit VoteCast(msg.sender, _proposalId, _support);
    }


    function _voteOnInvestmentProposal(uint256 _proposalId, bool _support) internal  {
        require(_proposalId > 0 && _proposalId <= investmentProposalCount, "Invalid proposal ID");
        require(investmentProposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote");
        require(!investmentProposalVoters[_proposalId][msg.sender], "Already voted on this proposal");

        if (_support) {
            investmentProposals[_proposalId].yesVotes += 1;
        } else {
            investmentProposals[_proposalId].noVotes += 1;
        }

        investmentProposalVoters[_proposalId][msg.sender] = true;
        emit VoteCast(msg.sender, _proposalId, _support);
    }


    // --- Pause/Unpause Functionality ---

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // --- Treasury Management ---
    function setTreasuryToken(IERC20 _newTreasuryToken) public onlyOwner {
        treasuryToken = _newTreasuryToken;
    }


    function depositToTreasury(uint256 _amount) public {  // Allows anyone to deposit to the treasury
        treasuryToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // --- Membership Management (Example) ---
    function grantMembership(address _member) public onlyOwner {
        membershipNFT.mint(_member);
    }
}
