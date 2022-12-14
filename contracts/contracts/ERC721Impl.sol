pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract ERC721Impl is IERC721, IERC721Enumerable, IERC721Metadata {
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _approvals;
    mapping(address => mapping(address => bool)) private _operators;
    string private _name;
    string private _symbol;
    uint256 private _supply;
    uint256[] private _tokenIds;

    /**
     * 
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ERC721

    /**
     * 
     */
    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "Cannot query zero address");
        return _balances[_owner];
    }

    /**
     * 
     */
    function ownerOf(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "TokenId not minted");
        return owner;
    }

    /**
     * 
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public override {
        transferFrom(_from, _to, _tokenId);
        // When transfer is complete, this function checks if `_to` is a smart contract (code size > 0)
        if (_to.code.length > 0) {
            bytes4 result = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
            require(result == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")), "IERC721Receiver error");
        }
    }

    /**
     * 
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * 
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        // Throws if `_tokenId` is not a valid NFT
        address owner = _owners[_tokenId];
        require(owner != address(0), "TokenId not minted");
        // Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT
        require(msg.sender == owner || _operators[owner][msg.sender] || _approvals[_tokenId] == msg.sender, "No permission to transfer");
        // Throws if `_from` is not the current owner
        require(_from == owner, "From is not current owner");
        // Throws if `_to` is the zero address
        require(_to != address(0), "To address is zero address");

        _balances[_from]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;
        
        delete _approvals[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * 
     */
    function approve(address _approved, uint256 _tokenId) public override {
            require(exists(_tokenId), "Invalid tokenId");

            address owner = _owners[_tokenId];
            require(msg.sender == owner || _operators[owner][msg.sender], "You are not owner or operator");

            if (_approved == address(0)) {
                delete _approvals[_tokenId];
            } else {
                _approvals[_tokenId] = _approved;
            }

            emit Approval(owner, _approved, _tokenId);
    }

    /**
     * 
     */
    function setApprovalForAll(address _operator, bool _approved)
        public
        override
    {
        require(msg.sender != _operator, "You cant approve yourself!");
        require(_operator != address(0), "You cannot approve zero address");

        if (_approved) {
            _operators[msg.sender][_operator] = true;
        } else {
            delete _operators[msg.sender][_operator];
        }

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * 
     */
    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        require(_owners[_tokenId] != address(0), "Token Id not valid");
        return _approvals[_tokenId];
    }

    /**
     * 
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return _operators[_owner][_operator];
    }

    // ERC721Metadata

    /**
     * 
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * 
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * 
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(exists(_tokenId), "Invalid tokenId");
        return "";
    }

    // ERC721Enumerable

    /**
     * 
     */
    function totalSupply() public view override returns (uint256) {
        return _supply;
    }

    /**
     * 
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "Zero Adress");
        require(_index < balanceOf(_owner), "ERC721: owner index out of bounds");
        
        
        
        // // total supply is the token count
        uint256 total = totalSupply();
        uint256 count = 0; 

        
        for (uint256 i = 0; i < total; i++){
            if (_owner == _owners[tokenByIndex(i)]){
                count++; 
            }

            if(count - 1 == _index){
                return tokenByIndex(i);
            }
        }
    }

    /**
     * 
     */
    function tokenByIndex(uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        require(_index < totalSupply(), "Index out of bounds");
        
        return _tokenIds[_index];
    }

    // ERC165

    /**
     * 
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return 
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x780e9d63 // ERC721Enumerable
        ;
    }

    // Other

    function exists(uint256 _tokenId) public view returns(bool) {
        return _owners[_tokenId] != address(0);
    }

    function mint(address _to, uint256 _tokenId) internal virtual {
        require(msg.sender == _to, "You can only mint for yourself!");
        require(_owners[_tokenId] == address(0), "NFT with this tokenID already exists!");

        _balances[_to]++;
        _owners[_tokenId] = _to;

        _supply++;
        _tokenIds.push(_tokenId);

        emit Transfer(address(0), _to, _tokenId);
    } 

}
