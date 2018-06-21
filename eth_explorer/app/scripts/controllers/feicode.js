class Feicode {
    constructor() {
        this.max_input_length = 127;
        this.max_output_length = 254;
        this.forbidden_first_char_map = new Map();
        this.charToNumMap = new Map();
        this.numToCharMap = new Map([
            ['00', "\n"],
            ['01', "\r"],
            ['02', '$'],
            ['03', "\t"],
            ['04', '©'],
            ['05', '¥'],
            ['06', ' '],
            ['07', '\\'],
            ['08', '|'],
            ['09', '-'],
            ['10', '0'],
            ['11', '1'],
            ['12', '2'],
            ['13', '3'],
            ['14', '4'],
            ['15', '5'],
            ['16', '6'],
            ['17', '7'],
            ['18', '8'],
            ['19', '9'],
            ['20', 'a'],
            ['21', 'b'],
            ['22', 'c'],
            ['23', 'd'],
            ['24', 'e'],
            ['25', 'f'],
            ['26', 'g'],
            ['27', 'h'],
            ['28', 'i'],
            ['29', 'j'],
            ['30', 'k'],
            ['31', 'l'],
            ['32', 'm'],
            ['33', 'n'],
            ['34', 'o'],
            ['35', 'p'],
            ['36', 'q'],
            ['37', 'r'],
            ['38', 's'],
            ['39', 't'],
            ['40', 'u'],
            ['41', 'v'],
            ['42', 'w'],
            ['43', 'x'],
            ['44', 'y'],
            ['45', 'z'],
            ['46', 'A'],
            ['47', 'B'],
            ['48', 'C'],
            ['49', 'D'],
            ['50', 'E'],
            ['51', 'F'],
            ['52', 'G'],
            ['53', 'H'],
            ['54', 'I'],
            ['55', 'J'],
            ['56', 'K'],
            ['57', 'L'],
            ['58', 'M'],
            ['59', 'N'],
            ['60', 'O'],
            ['61', 'P'],
            ['62', 'Q'],
            ['63', 'R'],
            ['64', 'S'],
            ['65', 'T'],
            ['66', 'U'],
            ['67', 'V'],
            ['68', 'W'],
            ['69', 'X'],
            ['70', 'Y'],
            ['71', 'Z'],
            ['72', '~'],
            ['73', '!'],
            ['74', '@'],
            ['75', '#'],
            ['76', '$'],
            ['77', '%'],
            ['78', '^'],
            ['79', '&'],
            ['80', '*'],
            ['81', '('],
            ['82', ')'],
            ['83', '_'],
            ['84', '+'],
            ['85', '{'],
            ['86', '}'],
            ['87', '['],
            ['88', ']'],
            ['89', ';'],
            ['90', '\''],
            ['91', ','],
            ['92', '.'],
            ['93', '/'],
            ['94', '<'],
            ['95', '>'],
            ['96', '?'],
            ['97', ':'],
            ['98', '"'],
            ['99', '`'],
        ]);
        this.flip_map();
    }

    /**
     * 反转map
     * @returns {Map<any, any>}
     */
    flip_map(){
        var i = 0;
        for (var [key, value] of this.numToCharMap) {
            this.charToNumMap.set(value, key);
            if ( i++ < 10) {
                this.forbidden_first_char_map.set(value, key);
            }
        }
    }

    /**
     * 检测字符串是否可以由 字母字符串 转为 数字字符串
     * @param str
     * @returns {boolean}
     */
    isFeicodeEncodable(str) {
        let length = str.length;
        if (length > this.max_input_length) {
            console.log('长度');
            return false;
        }

        // 判断首字母是否合法
        let first_char = str.substr(0, 1);
        if (this.forbidden_first_char_map.has(first_char)) {
            console.log('首字母不合法');
            return false;
        }

        // 判断是不是每个字符都有对应的映射
        for (var i = 0; i < length; i++) {
            if (!this.charToNumMap.has(str[i])) {
                console.log(str[i] + '无映射');
                return false;
            }
        }
        return true;
    }

    /**
     * 检测字符串是否可以由 数字字符串 转为 字母字符串
     * @param encode_str
     * @returns {boolean}
     */
    isFeicodeDecodable(encode_str) {
        let len = encode_str.length;
        // 判断长度是否超限
        if (len > this.max_output_length) return false;

        // 判断是否为偶数位数
        if (!this.is_even(len)) return false;
        
        // 判断是不是每个数字都有对应的映射
        let str_to_arr = this.split_str(encode_str);
        for (var i = 0; i < str_to_arr.length; i++) {
            if (!this.numToCharMap.has(str_to_arr[i])) {
                return false;
            }
        }

        return true;
    }

    is_even(len) {
        return len % 2 == 0;
    }

    split_str(str) {
        let reg = /\d{2}/g;
        return str.match(reg);
    }

    /**
     * 字母转数字
     * @param str
     * @returns {string}
     */
    feicodeEncode(str) {
        if (!this.isFeicodeEncodable(str)) return "";
        let len = str.length;
        let res = "";
        for (var i = 0; i < len; i++) {
            res += this.charToNumMap.get(str[i]);
        }

        return res;
    }

    /**
     * 数字转字母
     * @param str
     * @returns {string}
     */
    feicodeDecode(str) {
        if (!this.isFeicodeDecodable(str)) return "";
        let res = "";
        let str_to_arr = this.split_str(str);
        for (var i = 0; i < str_to_arr.length; i++) {
            res += this.numToCharMap.get(str_to_arr[i]);
        }
        return res;
    }
}




