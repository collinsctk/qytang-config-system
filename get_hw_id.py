import sys

try:
    from pyarmor.hdinfo import get_hd_info
except ImportError:
    print("错误: PyArmor 未安装。", file=sys.stderr)
    print("请运行以下命令进行安装: pip install pyarmor", file=sys.stderr)
    sys.exit(1)

def main():
    """
    收集并打印用于生成许可证的硬件信息。
    默认绑定到以太网MAC地址和硬盘序列号。
    """
    print("正在为许可证生成收集硬件信息...")
    
    try:
        # hdtype=1 用于以太网MAC地址
        # hdtype=2 用于硬盘序列号
        # 我们将绑定到MAC和硬盘，即 1 + 2 = 3
        hardware_info = get_hd_info(hdtype=3)

        print("\n" + "="*60)
        print("         用于软件授权的硬件指纹")
        print("="*60)
        print(hardware_info)
        print("="*60)
        print("\n重要提示: 请复制上面一行完整的硬件指纹信息，")
        print("并将其发送给您的软件提供商以获取您的许可证文件(license.lic)。")

    except Exception as e:
        print(f"\n收集硬件信息时发生错误: {e}", file=sys.stderr)
        print("请确保您有足够的权限访问硬件详细信息。", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
