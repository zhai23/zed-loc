import json
import sys

def check_http_headers(file_path):
    """检查翻译文件中的HTTP头部字段是否正确（应为空字符串）"""

    # 需要检查的关键HTTP头部字段
    critical_headers = [
        "Authorization",
        "Content-Type",
        "X-Api-Key",
        "Anthropic-Beta",
        "Bearer {}",
        "Bearer {token}",
        "Bearer {api_key}",
        "application/json"
    ]

    # 应该为空的错误消息（包含HTTP头部名称）
    critical_error_messages = [
        "missing Content-Type header",
        "invalid Content-Type header",
        "missing header `{key}`"
    ]

    issues_found = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 遍历所有文件和字符串
        for file_name, translations in data.items():
            if isinstance(translations, dict):
                for key, value in translations.items():
                    # 检查关键HTTP头部字段
                    if key in critical_headers:
                        if value != "":
                            issues_found.append({
                                'file': file_name,
                                'key': key,
                                'value': value,
                                'issue': 'HTTP头部字段被翻译了，应该为空字符串'
                            })

                    # 检查包含HTTP头部名称的错误消息
                    elif key in critical_error_messages:
                        if value != "":
                            issues_found.append({
                                'file': file_name,
                                'key': key,
                                'value': value,
                                'issue': '包含HTTP头部名称的错误消息被翻译了，应该为空字符串'
                            })

                    # 检查是否有中文翻译包含关键词
                    elif isinstance(value, str) and value != "":
                        for header in ["Authorization", "Content-Type", "Bearer"]:
                            if header.lower() in key.lower() and any(char >= '\u4e00' and char <= '\u9fff' for char in value):
                                issues_found.append({
                                    'file': file_name,
                                    'key': key,
                                    'value': value,
                                    'issue': f'可能错误翻译了包含"{header}"的字段'
                                })

    except Exception as e:
        print(f"读取文件时出错: {e}")
        return False

    # 输出检查结果
    if issues_found:
        print(f"❌ 在 {file_path} 中发现 {len(issues_found)} 个问题:")
        print("-" * 60)
        for i, issue in enumerate(issues_found, 1):
            print(f"{i}. 文件: {issue['file']}")
            print(f"   键: {issue['key']}")
            print(f"   值: {issue['value']}")
            print(f"   问题: {issue['issue']}")
            print()
        return False
    else:
        print(f"✅ {file_path} 检查通过，未发现HTTP头部翻译问题")
        return True

def main():
    """主函数"""
    files_to_check = [
        'zh.json',
        'zh-CN/zh-CN.json'
    ]

    all_good = True

    print("开始检查HTTP头部字段翻译问题...")
    print("=" * 60)

    for file_path in files_to_check:
        try:
            result = check_http_headers(file_path)
            all_good = all_good and result
        except FileNotFoundError:
            print(f"⚠️  文件未找到: {file_path}")
        except Exception as e:
            print(f"❌ 检查 {file_path} 时出错: {e}")
            all_good = False
        print()

    print("=" * 60)
    if all_good:
        print("✅ 所有检查通过！HTTP头部字段翻译正确。")
        print("现在可以重新编译Zed了。")
        sys.exit(0)
    else:
        print("❌ 发现问题，请修复后再重新编译。")
        sys.exit(1)

if __name__ == "__main__":
    main()
