import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IERC2981 is ERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256,bytes)")) == 0x6057361d
    /// bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x6057361d;
    /// _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @param _data - information used by extensions of this ERC.
    ///                Must not to be used by implementers of EIP-2981
    ///                alone.
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for _value sale price
    /// @return _royaltyPaymentData - information used by extensions of this ERC.
    ///                               Must not to be used by implementers of
    ///                               EIP-2981 alone.
    function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData);

    /// @notice Informs callers that this ERC721 supports ERC2981
    /// @dev If `_registerInterface(_INTERFACE_ID_ERC721ROYALTIES)` is called
    ///      in the initializer, this should be automatic
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements
    ///         `_INTERFACE_ID_ERC721ROYALTIES` and `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
