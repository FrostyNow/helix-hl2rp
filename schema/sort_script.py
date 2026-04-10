import re
import os

def sort_voices(input_path, output_path):
    # 경로 감지 규칙 완화: 따옴표 안에 / 가 들어있으면 경로로 간주
    PATH_REGEX = re.compile(r'"([^"]*/[^"]+)"')

    def get_sort_key(line):
        match = PATH_REGEX.search(line)
        if match:
            # 발견된 경로들 중 가장 마지막 것(보통 파일 경로 위치)을 기준으로 하되, 
            # 한 줄에 여러 경로가 있으면 첫 번째 것을 우선순위로 함
            paths = PATH_REGEX.findall(line)
            if paths:
                return paths[0].lower()
        return "zzzzzzzz"

    if not os.path.exists(input_path):
        return

    with open(input_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]

    sorted_lines = sorted(lines, key=get_sort_key)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted_lines) + '\n')

if __name__ == "__main__":
    input_file = "/Users/frosty/Documents/Garry's Mod/ixhl2rp/schema/unsorted.md"
    output_file = "/Users/frosty/Documents/Garry's Mod/ixhl2rp/schema/sorted.md"
    sort_voices(input_file, output_file)
