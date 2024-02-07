// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    // ****************** Data ***********************

    //Owner
    address owner;
    uint256 private counter;
    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals

    // 1st change: Vote Tracking
    // I like this implementation from Event Recording
    mapping(address => bool) private hasVoted;

    struct Proposal {
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 vote_limit; // When the total votes in the proposal reaches this limit, proposal ends
        bool is_active; // This shows if others can vote to our contract
    }


    //constructor
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier active() {
        require(proposal_history[counter].is_active == true);
        _;
    }

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "Address has already voted.");
        _;
    }

    // 2nd change: check vote limit to continue
    // note: I'm not sure if this is efficient
    modifier voteLimit(Proposal storage proposal){
        require(calculateCurrentState(proposal), "Vote limit reached!");
        _;
    }

    // ****************** Execute Functions ***********************


    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }

    function create(string calldata _description, uint256 _vote_limit) external onlyOwner {
        counter += 1;
        proposal_history[counter] = Proposal(_description, 0, 0, 0, _vote_limit, true);
    }
    

    function vote(uint8 choice) external active hasNotVoted voteLimit(proposal_history[counter]){
        Proposal storage proposal = proposal_history[counter];
        
        if (choice == 1)        proposal.approve += 1;
        else if (choice == 2)   proposal.reject += 1;
        else if (choice == 0)   proposal.pass += 1;

        // 3rd change: extra function used
        if ((proposal.vote_limit - getTotalVote() == 1)) {
            proposal.is_active = false;
        }
    }

    function terminateProposal() external onlyOwner active {
        proposal_history[counter].is_active = false;
    }

    // 4th change: remove the current state from struct
    //      but modify this function as a helper
    function calculateCurrentState(Proposal storage proposal) private view returns(bool) {
        uint256 approve = proposal.approve;
        uint256 reject = proposal.reject;
        uint256 pass = proposal.pass;
        
        // Calculate the average using bitwise shift operations
        // This should work fine
        uint256 average = ((approve + reject + pass) >> 1);

        if (average > reject + pass) {
            return true;
        } else {
            return false;
        }
    }


    // ****************** Query Functions ***********************

    function getCurrentProposal() external view returns(Proposal memory) {
        return proposal_history[counter];
    }

    function getProposal(uint256 number) external view returns(Proposal memory) {
        return proposal_history[number];
    }

    // 5th change: An helper function to get total vote number
    function getTotalVote() public view returns (uint256) {
        return proposal_history[counter].approve + proposal_history[counter].reject + proposal_history[counter].pass;
    }
}