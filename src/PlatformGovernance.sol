// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/math/SafeMath.sol";

import "src/GRNToken.sol";

contract PlatformGovernance is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    GRNToken public grnToken;
    
    uint256 public constant PROPOSAL_THRESHOLD = 100 * 10**18; 
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant EXECUTION_DELAY = 2 days;
    
    enum ProposalState { Pending, Active, Defeated, Succeeded, Executed }
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        ProposalState state;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    
    constructor(address _grnToken) {
        require(_grnToken != address(0), "Invalid GRN token address");
        grnToken = GRNToken(_grnToken);
    }
    
    function createProposal(string memory description) external returns (uint256) {
        require(grnToken.balanceOf(msg.sender) >= PROPOSAL_THRESHOLD, "Insufficient GRN balance");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp.add(VOTING_PERIOD);
        newProposal.state = ProposalState.Active;
        
        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }
    
    function vote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votes = grnToken.balanceOf(msg.sender);
        require(votes > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }
        
        emit VoteCast(proposalId, msg.sender, support, votes);
    }
    
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
        }
    }
    
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        return proposals[proposalId].state;
    }
}