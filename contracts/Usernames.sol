// solhint-disable-next-line
pragma solidity ^0.4.19;


contract Usernames {

    mapping(address => bytes32) public addressToUser;
    mapping(bytes32 => address) public userToAddress;

    event UserNamed(address indexed user, bytes32 indexed username);

    /**
     * Claim a username. Frees up a previously used one
     * @param _username to claim
     */
    function claimUsername(bytes32 _username) external {
        require(userToAddress[_username] == address(0));// Username must be free

        if (addressToUser[msg.sender] != bytes32(0)) { // If user already has username free it up
            userToAddress[addressToUser[msg.sender]] = address(0);
        }

        //all is well assign username
        addressToUser[msg.sender] = _username;
        userToAddress[_username] = msg.sender;

        emit UserNamed(msg.sender, _username);

    }

}
