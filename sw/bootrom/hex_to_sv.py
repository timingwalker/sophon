#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HEX文件转SystemVerilog常量数组转换器
输入格式：@地址行 + 数据行（每行多个十六进制字节，空格分隔）
输出格式：每4个字节组合成32位，输出为SystemVerilog数组
"""

import sys
import os
from datetime import datetime

def parse_hex_file(hex_file, depth=1024):
    """
    解析HEX文件，返回字节数组
    """
    with open(hex_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 初始化内存数组，全部填充0
    mem = bytearray(depth * 4)  # 假设每个元素4字节
    current_addr = 0

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue

        # 处理地址行
        if line.startswith('@'):
            # 提取地址（去掉@，取第一个空格前的部分）
            addr_part = line[1:].split()
            if addr_part:
                try:
                    current_addr = int(addr_part[0], 16)
                except ValueError:
                    print(f"警告：无法解析地址 '{line}'，跳过")
            i += 1
            continue

        # 处理数据行
        # 分割空格分隔的十六进制数据
        hex_bytes = line.split()

        for hex_byte in hex_bytes:
            try:
                # 将十六进制字符串转换为字节
                if 0 <= current_addr < len(mem):
                    mem[current_addr] = int(hex_byte, 16)
                current_addr += 1
            except ValueError:
                print(f"警告：无法解析十六进制数据 '{hex_byte}'，跳过")

        i += 1

    return mem

def bytes_to_32bit_words(mem_bytearray, depth=1024):
    """
    将字节数组转换为32位字列表
    注意：需要处理字节序（这里假设是小端格式）
    """
    words = []

    for i in range(0, min(len(mem_bytearray), depth * 4), 4):
        # 组合4个字节为32位字（小端格式：低字节在低地址）
        if i + 3 < len(mem_bytearray):
            word = (mem_bytearray[i+3] << 24) | (mem_bytearray[i+2] << 16) | (mem_bytearray[i+1] << 8) | mem_bytearray[i]
        else:
            # 如果不足4字节，用0填充
            word = 0
            for j in range(min(4, len(mem_bytearray) - i)):
                word |= mem_bytearray[i + j] << (j * 8)
        words.append(word)

    # 如果不足指定深度，填充0
    while len(words) < depth:
        words.append(0)

    return words[:depth]  # 确保不超过指定深度

def generate_sv_array(words, output_file, array_name="mem"):
    """
    生成SystemVerilog数组定义
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        # 写入注释头
        f.write(f"// Auto-generated from HEX file\n")
        f.write(f"// Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"// Array depth: {len(words)} x 32-bit\n\n")

        f.write(f"module boot_code\n")
        f.write(f"(\n")
        f.write(f"    input  logic        CLK,\n")
        f.write(f"    input  logic        RSTN,\n")
        f.write(f"    input  logic        CSN,\n")
        f.write(f"    input  logic [10:0]  A,\n")
        f.write(f"    output logic [31:0] Q\n")
        f.write(f"  );\n\n")

        # 写入数组定义
        f.write(f"logic [31:0] {array_name} [0:{len(words)-1}] = ")
        f.write("'{\n")

        # 写入数据
        for i, word in enumerate(words):
            # 格式化十六进制：每4位加下划线
            hex_str = f"{word:08X}"
            formatted_hex = f"{hex_str[0:4]}_{hex_str[4:8]}"

            f.write(f"  32'h{formatted_hex}")

            if i < len(words) - 1:
                f.write(",\n")
            else:
                f.write("\n")

        f.write("};\n\n")

        f.write(f"  always_ff @(posedge CLK, negedge RSTN)\n")
        f.write(f"  begin\n")
        f.write(f"    if (~RSTN)\n")
        f.write(f"      Q <= '0;\n")
        f.write(f"    else if (~CSN)\n")
        f.write(f"      Q <= mem[A];\n")
        f.write(f"  end\n\n")
        f.write(f"endmodule\n")



def main():
    if len(sys.argv) < 3:
        print("用法: python hex2sv.py <输入HEX文件> <输出SV文件> [选项]")
        print("\n选项:")
        print("  -n NAME     数组名称 (默认: mem)")
        print("  -d DEPTH    数组深度 (默认: 1024)")
        print("\n示例:")
        print("  python hex2sv.py boot.hex boot.sv")
        print("  python hex2sv.py boot.hex output.sv -n rom_data -d 2048")
        return

    # 解析参数
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    array_name = "mem"
    depth = 1024

    # 解析可选参数
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == "-n" and i + 1 < len(sys.argv):
            array_name = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "-d" and i + 1 < len(sys.argv):
            depth = int(sys.argv[i + 1])
            i += 2
        else:
            i += 1

    # 检查输入文件是否存在
    if not os.path.exists(input_file):
        print(f"错误: 文件 '{input_file}' 不存在")
        sys.exit(1)

    try:
        print(f"正在解析HEX文件: {input_file}")
        print(f"数组深度: {depth}")

        # 1. 解析HEX文件
        mem_bytes = parse_hex_file(input_file, depth)
        print(f"读取字节数: {len(mem_bytes)}")

        # 2. 转换为32位字
        words = bytes_to_32bit_words(mem_bytes, depth)
        print(f"32位字数: {len(words)}")

        # 3. 生成SystemVerilog文件
        generate_sv_array(words, output_file, array_name)
        print(f"已生成SV文件: {output_file}")

        # 4. 打印统计信息
        print(f"\n统计信息:")
        print(f"  - 非零值: {sum(1 for w in words if w != 0)}")
        print(f"  - 零值: {sum(1 for w in words if w == 0)}")

        # 5. 显示前几个值作为示例
        print(f"\n前5个值:")
        for i in range(min(5, len(words))):
            print(f"  {array_name}[{i}] = 32'h{words[i]:08X}")

    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
