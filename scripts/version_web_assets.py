"""Give application entrypoints content-addressed URLs across deployments."""
import hashlib
from pathlib import Path


def version_entrypoints(static: Path):
    main = static / 'main.dart.js'
    main_name = 'main.dart.' + hashlib.sha256(main.read_bytes()).hexdigest()[:16] + '.js'
    (static / main_name).write_bytes(main.read_bytes())
    bootstrap = static / 'flutter_bootstrap.js'
    text = bootstrap.read_text()
    if '"mainJsPath":"main.dart.js"' not in text:
        raise ValueError('Flutter entrypoint configuration was not found')
    text = text.replace('"mainJsPath":"main.dart.js"', '"mainJsPath":"' + main_name + '"')
    bootstrap.write_text(text)
    bootstrap_name = 'flutter_bootstrap.' + hashlib.sha256(text.encode()).hexdigest()[:16] + '.js'
    (static / bootstrap_name).write_text(text)
    index = static / 'index.html'
    html = index.read_text()
    if 'src="flutter_bootstrap.js"' not in html:
        raise ValueError('Flutter bootstrap script was not found')
    index.write_text(html.replace('src="flutter_bootstrap.js"', 'src="' + bootstrap_name + '"'))
