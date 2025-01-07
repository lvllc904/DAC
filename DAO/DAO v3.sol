pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DAOToken is ERC20 {
    constructor() ERC20("DAO Token", "DAO") {}
}

contract MembershipNFT is ERC721Enumerable {
    constructor() ERC721("DAO Membership", "MEMB") {}

    function mint(address _to) public onlyOwner {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(_to, tokenId);
    }
}

contract DAO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum ProposalState { Pending, Active, Passed, Rejected, Executed }

    struct Proposal {
        string description;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 quorum; // Minimum votes required for the proposal to be valid
        ProposalState state;
        address proposer;
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
    uint256 public proposalCount;
    uint256 public investmentProposalCount;

    // Quorum percentage (e.g., 50% of total token supply)
    uint256 public constant QUORUM_PERCENTAGE = 50; 

    constructor(address _tokenAddress, address _membershipNFTAddress) {
        token = DAOToken(_tokenAddress);
        membershipNFT = MembershipNFT(_membershipNFTAddress);
    }

    // --- Proposal Functions ---

    function createProposal(string memory _description, uint256 _votingPeriod) public {
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can create proposals"); 

        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            votingStart: block.timestamp,
            votingEnd: block.timestamp + _votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            quorum: (token.totalSupply() * QUORUM_PERCENTAGE) / 100, 
            state: ProposalState.Pending,
            proposer: msg.sender
        });
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote"); 

        if (_support) {
            proposals[_proposalId].yesVotes += 1; // One member, one vote
        } else {
            proposals[_proposalId].noVotes += 1;
        }
    }

    function finalizeProposal(uint256 _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(block.timestamp > proposals[_proposalId].votingEnd, "Voting has not ended");

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.yesVotes >= proposal.quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Passed;
        } else {
            proposal.state = ProposalState.Rejected;
        }
    }

    // --- Investment Proposal Functions ---

    function createInvestmentProposal(
        string memory _description, 
        address _beneficiary, 
        uint256 _amount, 
        uint256 _votingPeriod
    ) public {
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

    function voteOnInvestmentProposal(uint256 _proposalId, bool _support) public {
        require(_proposalId > 0 && _proposalId <= investmentProposalCount, "Invalid proposal ID");
        require(investmentProposals[_proposalId].state == ProposalState.Active, "Voting not active");
        require(membershipNFT.balanceOf(msg.sender) > 0, "Only members can vote"); 

        if (_support) {
            investmentProposals[_proposalId].yesVotes += 1; // One member, one vote
        } else {
            investmentProposals[_proposalId].noVotes += 1;
        }
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

    // ... (Implement Treasury Management, Fair Use Enforcement, etc.) ...

}