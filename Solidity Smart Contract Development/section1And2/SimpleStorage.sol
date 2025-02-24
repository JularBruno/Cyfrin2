// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// source with more basic things https://github.com/Cyfrin/remix-storage-factory-cu/blob/main/SimpleStorage.sol
contract SimpleStorage {
    // types: https://docs.soliditylang.org/en/v0.8.28/types.html
    
    // public to see number, creates getter function, such as retrieve example
    // this is called a state variable or outsiide the function variable
    uint256 myFavoriteNumber; // gets initialized to 0 when no value
    // implicilty storage because it lives outside function calls
    
    // uint256[] listOfFavoriteNumbers; // array
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    // static array can be [3] 3 people
    Person[] public listOfPeople;

    // ie: chelsea -> 232
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        myFavoriteNumber = _favoriteNumber;
    }

    // view, pure
    // view cant modify state, pure cant even read
    function retrieve() public view returns(uint256) {
        return myFavoriteNumber;
    }

    // calldata, memory, storage
    // SUMMARY: struct, mappings and arrays need to be given memory keyword. String is an array of bytes thats why it needs it.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Person memory newPerson = Person(_favoriteNumber, _name)
        // listOfPeople.push();
        listOfPeople.push(Person(_favoriteNumber, _name));
        
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
