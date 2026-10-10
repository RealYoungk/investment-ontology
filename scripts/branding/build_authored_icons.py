#!/usr/bin/env python3
"""Code-native service identity icons for researched but unresolved issuers.
These are not official CI or copies of issuer artwork. No paid generation API.
"""
import hashlib
import html
import importlib.util
import json
import re
from pathlib import Path

spec = importlib.util.spec_from_file_location('icons', Path(__file__).with_name('collect_company_icons.py'))
icons = importlib.util.module_from_spec(spec)
spec.loader.exec_module(icons)

# Explicit individual artwork. Sources establish issuer identity/activity only.
ARTWORK = {
 '415640': ('#303842', '#FFCB36', '<path d="M17 62h62M26 62V33m44 29V33M26 38Q48 66 70 38M26 44l-9 13m53-13 9 13M37 51v11m11-7v7m11-11v11" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round"/>', 'https://kbif.co.kr/ko/main/index.do', 'bridge'),
 '496320': ('#063A4B', '#78DDE0', '<path d="m48 17 26 15v31L48 79 22 63V32Z" fill="none" stroke="currentColor" stroke-width="7"/><circle cx="48" cy="48" r="14" fill="none" stroke="currentColor" stroke-width="6"/><path d="M48 25v9m0 28v9M28 36l8 5m24 14 8 5M28 60l8-5m24-14 8-5" stroke="currentColor" stroke-width="5"/>', 'https://bonsystems.com/', 'precision drive'),
 '004700': ('#75482E', '#F8D9AC', '<path d="m22 24 26 13 26-13v18L48 55 22 42Zm0 27 26 13 26-13v18L48 82 22 69Z" fill="currentColor"/>', 'http://chokwang.co.kr/', 'folded leather'),
 '243870': ('#253C59', '#FF8576', '<path d="m48 18 28 16v29L48 79 20 63V34Z" fill="none" stroke="currentColor" stroke-width="6"/><path d="m20 34 28 16 28-16M48 50v29" fill="none" stroke="currentColor" stroke-width="6"/><path d="m48 32 13 8v15l-13 8-13-8V40Z" fill="currentColor"/>', 'https://itcencore.com/010000/010400/page.do', 'core cube'),
 '189350': ('#292552', '#B2A0FF', '<circle cx="48" cy="48" r="27" fill="none" stroke="currentColor" stroke-width="6"/><circle cx="48" cy="48" r="15" fill="none" stroke="currentColor" stroke-width="5"/><path d="M48 15v19m0 28v19M15 48h19m28 0h19" stroke="currentColor" stroke-width="5"/><circle cx="48" cy="48" r="5" fill="currentColor"/>', 'https://kind.krx.co.kr/external/2026/03/09/000173/20260309000424/11011.htm', 'optical axis'),
 '266350': ('#174E94', '#8EDFFF', '<path d="m48 14 9 23 25 2-19 17 6 25-21-14-21 14 6-25-19-17 25-2Z" fill="currentColor"/><path d="m48 29 5 14 14 2-11 10 3 14-11-8-11 8 3-14-11-10 14-2Z" fill="#174E94"/>', 'https://pangsky.kr/', 'sky star'),
 '140660': ('#123C70', '#76D8F0', '<circle cx="48" cy="48" r="17" fill="none" stroke="currentColor" stroke-width="5"/><ellipse cx="48" cy="48" rx="34" ry="13" transform="rotate(-35 48 48)" fill="none" stroke="currentColor" stroke-width="4"/><circle cx="72" cy="28" r="7" fill="currentColor"/><path d="M40 48h16M48 40v16" stroke="currentColor" stroke-width="4"/>', 'https://kind.krx.co.kr/external/2025/03/20/001600/20250320006500/11011.htm', 'satellite orbit'),
 '266170': ('#752D35', '#FFB1A1', '<path d="m48 17 16 22h-9l16 22H54v18H42V61H25l16-22h-9Z" fill="currentColor"/><path d="m24 34 9 13h-5l9 13H19l9-13h-5Zm48 0 9 13h-5l9 13H67l9-13h-5Z" fill="currentColor" opacity=".55"/>', 'https://englishdart.fss.or.kr/dsbc001/selectPopup.ax?selectKey=00990396', 'redwood grove'),
 '341170': ('#4D367B', '#D6B8FF', '<g transform="rotate(-35 48 48)"><rect x="20" y="34" width="56" height="28" rx="14" fill="none" stroke="currentColor" stroke-width="6"/><path d="M48 34v28M27 43h13" stroke="currentColor" stroke-width="5" stroke-linecap="round"/></g><circle cx="71" cy="23" r="5" fill="currentColor"/><circle cx="23" cy="72" r="4" fill="currentColor"/>', 'http://www.futuremedicine.co.kr/', 'medicine capsule'),
}
FAMILIES = [
 ('엔에이치', '#125199', '#FFD456'), ('한국', '#D85035', '#FFE1BB'),
 ('KB', '#48433B', '#FFCD32'), ('하나', '#08796C', '#B6F0D4'),
 ('삼성', '#20208E', '#BEBEFF'), ('IBKS', '#1E559A', '#9EDAFD'),
 ('디비', '#19764F', '#BBE697'), ('미래에셋', '#CC641E', '#FFE4B5'),
 ('교보', '#245148', '#8DE0B5'), ('키움', '#762B78', '#EDB4E9'),
 ('신영', '#54473F', '#E7D4BF'), ('신한', '#2549A1', '#B6CDFF'),
 ('유진', '#293A64', '#A7D8F2'), ('유안타', '#BB3347', '#FEC3CB'),
 ('엘에스', '#285C87', '#94DAFF'),
]
SEGMENTS = {'0':'abcdef', '1':'bc', '2':'abged', '3':'abgcd', '4':'fgbc', '5':'afgcd', '6':'afgecd', '7':'abc', '8':'abcdefg', '9':'abfgcd'}
LINES = {'a':(2,0,10,0), 'b':(12,2,12,10), 'c':(12,14,12,22), 'd':(2,24,10,24), 'e':(0,14,0,22), 'f':(0,2,0,10), 'g':(2,12,10,12)}

def digits(value):
    start = 48 - (len(value)*18-6)/2
    parts=[]
    for i,ch in enumerate(value):
        for segment in SEGMENTS[ch]:
            x1,y1,x2,y2=LINES[segment]
            parts.append(f'<path d="M{start+i*18+x1} {60+y1}L{start+i*18+x2} {60+y2}"/>')
    return '<g fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round">'+''.join(parts)+'</g>'

def artwork(row):
    code,name=row['stockCode'],row['name']
    if '스팩' in name:
        family,bg,fg=next((x for x in FAMILIES if name.startswith(x[0])), ('스팩','#355D84','#C1E1FF'))
        number=re.search(r'(\d+)호',name)
        if not number:raise ValueError('SPAC series number is absent')
        body='<path d="M43 29l-6-6a12 12 0 0 0-17 17l9 9a12 12 0 0 0 17 0l6-6M53 43l6 6a12 12 0 0 0 17-17l-9-9a12 12 0 0 0-17 0l-6 6M36 40l24-10" fill="none" stroke="currentColor" stroke-width="6" stroke-linecap="round"/>'+digits(number.group(1))
        return bg,fg,body,None, f'{family} SPAC series {number.group(1)}'
    return ARTWORK[code]

if __name__=='__main__':
    rows=json.loads(icons.MANIFEST.read_text())
    created=[]
    for row in rows:
        if row['status']!='missing' and row.get('method')!='service-authored-vector-identity':continue
        bg,fg,body,source,concept=artwork(row)
        body=body.replace('currentColor',fg)
        svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><title>{html.escape(row["name"])} — service identity icon</title><rect width="96" height="96" rx="20" fill="{bg}"/><g color="{fg}">{body}</g></svg>\n'
        dest=icons.ASSETS/(row['stockCode']+'.svg');dest.write_text(svg)
        if row.get('pageUrl'):row['attemptedOriginalPageUrl']=row['pageUrl']
        for key in ('pageUrl','imageUrl','sourceSha256','sourceHashKind','originalSha256','originalFilename'):
            row.pop(key,None)
        row['acquisitionFailure']=row.get('acquisitionFailure') or row.pop('reason','Original or verified stock identity image unavailable')
        row.update(status='ready',method='service-authored-vector-identity',filename=dest.name,vectorSha256=hashlib.sha256(svg.encode()).hexdigest(),bytes=dest.stat().st_size,width=96,height=96,onDark=False,identitySourceUrl=source,designConcept=concept,officialArtwork=False,checkedAt='2026-10-07')
        created.append(row['stockCode'])
    print('Service-authored icons:', len(created), created)
    print(icons.publish(rows))
