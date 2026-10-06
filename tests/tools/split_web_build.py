#!/usr/bin/env python3
"""웹 빌드 후처리: index.wasm을 여러 조각으로 나누고, 페이지에서 다시 합치도록 index.html을 고친다.

파일 하나당 크기 제한과 확장자 제한(.pck 불가)이 있는 호스팅에 올리기 위한 도구다.
index.pck도 .wasm 확장자로 이름을 바꾸고, 로더가 원래 이름 요청을 바꿔서 받는다.
사용법: python3 tests/tools/split_web_build.py build/web
"""
import json
import os
import re
import sys

CHUNK_BYTES = 14 * 1024 * 1024
WASM_NAME = "index.wasm"
PCK_NAME = "index.pck"
PCK_RENAMED = "index.pck.wasm"
MARKER = "<!-- wasm-chunk-loader -->"
## 문서 골격(doctype/html/head/body)을 뺀 페이지 조각. 골격을 자동으로 씌우는 호스팅용이다.
FRAGMENT_NAME = "root-access.html"

LOADER_TEMPLATE = """{marker}
<script>
(function () {{
	// 이름을 바꾸거나 조각낸 파일을 받아서 원래 파일 하나처럼 Response를 돌려준다.
	const PARTS = {parts};
	const originalFetch = window.fetch.bind(window);
	window.fetch = function (input, init) {{
		const url = typeof input === "string" ? input : input.url;
		const name = url.split("/").pop().split("?")[0];
		if (!PARTS[name]) {{
			return originalFetch(input, init);
		}}
		return Promise.all(PARTS[name].map(function (part) {{
			return originalFetch(part).then(function (res) {{
				if (!res.ok) {{
					throw new Error("조각 다운로드 실패: " + part + " (" + res.status + ")");
				}}
				return res.arrayBuffer();
			}});
		}})).then(function (buffers) {{
			const type = name.endsWith(".wasm") ? "application/wasm" : "application/octet-stream";
			const blob = new Blob(buffers, {{ type: type }});
			return new Response(blob, {{ status: 200, headers: {{ "Content-Type": type }} }});
		}});
	}};
}})();
</script>
"""


def main() -> None:
	build_dir = sys.argv[1] if len(sys.argv) > 1 else "build/web"
	wasm_path = os.path.join(build_dir, WASM_NAME)
	html_path = os.path.join(build_dir, "index.html")

	with open(wasm_path, "rb") as f:
		data = f.read()
	parts = []
	for i in range(0, len(data), CHUNK_BYTES):
		part_name = f"index.part{len(parts)}.wasm"
		with open(os.path.join(build_dir, part_name), "wb") as out:
			out.write(data[i:i + CHUNK_BYTES])
		parts.append(part_name)
	os.remove(wasm_path)
	os.replace(os.path.join(build_dir, PCK_NAME), os.path.join(build_dir, PCK_RENAMED))

	with open(html_path, encoding="utf-8") as f:
		html = f.read()
	if MARKER not in html:
		loader = LOADER_TEMPLATE.format(marker=MARKER, parts=json.dumps({WASM_NAME: parts, PCK_NAME: [PCK_RENAMED]}))
		html = html.replace('<script src="index.js"></script>', loader + '<script src="index.js"></script>', 1)
	with open(html_path, "w", encoding="utf-8") as f:
		f.write(html)
	_write_fragment(html, os.path.join(build_dir, FRAGMENT_NAME))
	print(f"{WASM_NAME} -> {len(parts)}개 조각: {', '.join(parts)}")


def _write_fragment(html: str, path: str) -> None:
	html = re.sub(r"<!DOCTYPE html>\s*", "", html)
	html = re.sub(r"</?html[^>]*>", "", html)
	html = re.sub(r"</?head>", "", html)
	html = re.sub(r"</?body>", "", html)
	html = re.sub(r"<meta[^>]*>\s*", "", html)
	html = html.replace(
		"html, body, #canvas {",
		"html, body {\n\theight: 100%;\n\tcolor-scheme: dark;\n\tbackground-color: #000;\n}\n\nhtml, body, #canvas {",
		1,
	)
	with open(path, "w", encoding="utf-8") as f:
		f.write(html.strip() + "\n")


if __name__ == "__main__":
	main()
