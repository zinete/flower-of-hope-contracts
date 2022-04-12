// SPDX-License-Identifier: MIT
// flower of hope
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/Base64.sol";
import "./library/HexStrings.sol";
import "./library/ToColor.sol";

contract Flower is ERC721, Ownable {
    // 计数器, 只能递增或递减
    Counters.Counter private _tokenIds;
    // 使 uint256 具有 toHexString 功能
    using Strings for uint256;
    // 使 uint160 具有自定义 toHexString 功能
    using HexStrings for uint160;
    // 使 bytes3 可以方便生成前端颜色表示
    using ToColor for bytes3;
    // 计数功能，递增token id
    using Counters for Counters.Counter;

    uint256 mintDeadline = block.timestamp + 24 hours;
    // 用于保存每一个铸造的 Flower 的特征，其中，hope 表示希望值
    mapping(uint256 => bytes3) private color;
    mapping(uint256 => uint256) private hope;

    // 构造函数
    constructor() public ERC721("Flower of Hope", "HOPE") {}

    // 希望之花
    function mintFlower() public returns (uint256) {
        // 每次铸造前自增 _tokenIds，确保 _tokenIds 唯一
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        // 铸造者与 tokenId 绑定
        _mint(msg.sender, id);
        // keccak256可以将任意长度的输入压缩成64位16进制的数，且哈希碰撞的概率近乎为0.
        // 随机生成对应 tokenId 的属性
        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                id
            )
        );

        /**
          将随机数转换为颜色
          bytes2(predictableRandom[0]) 对应最低位蓝色数值，
          bytes2(predictableRandom[1]) >> 8 )对应中间位绿色数值，
          bytes3(predictableRandom[2]) >> 16  对应最高位红色数值；
         */
        color[id] =
            bytes2(predictableRandom[0]) |
            bytes2(predictableRandom[1] >> 8) |
            bytes3(predictableRandom[2] >> 16);

        hope[id] = 60 + (500 * uint256(uint8(predictableRandom[3]))) / 255;

        return id;
    }

    // 获取tokenId 对应的tokenUrl
    function tokenURI(uint256 id) public view override returns (string memory) {
        // 检查tokenId是否存在
        require(_exists(id), "Token does not exist");
        string memory name = string(
            abi.encodePacked("Flower #", id.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "this Flower is the color #",
                color[id].toColor(),
                "cool",
                uint2str(hope[id]),
                "!!!"
            )
        );
        string memory image = Base64.encode(bytes(generateSvgById(id)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "external_url":"https://burnyboys.com/token/',
                            id.toString(),
                            '", "attributes": [{"trait_type": "color", "value": "#',
                            color[id].toColor(),
                            '"},{"trait_type": "hope", "value": ',
                            uint2str(hope[id]),
                            '}], "owner":"',
                            (uint160(ownerOf(id))).toHexString(20),
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            );
    }

    // 生成 token id 对应的 svg 代码
    function generateSvgById(uint256 id) internal view returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
                renderTokenById(id),
                "</svg>"
            )
        );
        return svg;
    }

    // 生成 tokenId 对应的 svg 代码 用来绘制图像
    function renderTokenById(uint256 id) internal view returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                '<g id="eye1">',
                '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_1" cy="154.5" cx="181.5" stroke="#000" fill="#fff"/>',
                '<ellipse ry="3.5" rx="2.5" id="svg_3" cy="154.5" cx="173.5" stroke-width="3" stroke="#000" fill="#000000"/>',
                "</g>",
                '<g id="head">',
                '<ellipse fill="#',
                color[id].toColor(),
                '" stroke-width="3" cx="204.5" cy="211.80065" id="svg_5" rx="',
                hope[id].toString(),
                '" ry="51.80065" stroke="#000"/>',
                "</g>",
                '<g id="eye2">',
                '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_2" cy="168.5" cx="209.5" stroke="#000" fill="#fff"/>',
                '<ellipse ry="3.5" rx="3" id="svg_4" cy="169.5" cx="208" stroke-width="3" fill="#000000" stroke="#000"/>',
                "</g>"
            )
        );

        return render;
    }

    // 将uint 转换成字符串 例如 123 转换成 '123'
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
