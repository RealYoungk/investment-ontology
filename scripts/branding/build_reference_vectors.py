#!/usr/bin/env python3
"""Build service vector artwork for unresolved issuers from public stock-page
identity references. Originals remain preferred. No runtime third-party fetch.
"""
import argparse,concurrent.futures,hashlib,importlib.util,io,json
from pathlib import Path
from PIL import Image
import vtracer
spec=importlib.util.spec_from_file_location('icons',Path(__file__).with_name('collect_company_icons.py'))
icons=importlib.util.module_from_spec(spec);spec.loader.exec_module(icons)
REF=icons.OUT/'reference-artwork';REF.mkdir(exist_ok=True)

def draw(row):
    code=row['stockCode']
    url=f'https://static.toss.im/png-icons/securities/icn-sec-fill-{code}.png'
    try:
        data,source=icons.fetch(url)
        im=Image.open(io.BytesIO(data)).convert('RGBA')
        if im.width<24 or im.height<24 or not im.getbbox():raise ValueError('Empty or undersized identity reference')
        reference=REF/(code+'.png');reference.write_bytes(data)
        output=icons.ASSETS/(code+'.svg')
        vtracer.convert_image_to_svg_py(str(reference),str(output),colormode='color',hierarchical='stacked',mode='spline',filter_speckle=1,color_precision=8,layer_difference=8,corner_threshold=60,length_threshold=3.0,max_iterations=10,splice_threshold=45,path_precision=3)
        vector=output.read_bytes()
        if len(vector)>250000:raise ValueError('Reference vector too complex')
        result=dict(row);result.pop('reason',None)
        result.update(status='ready',pageUrl=f'https://www.tossinvest.com/stocks/A{code}/order',imageUrl=source,sourceSha256=hashlib.sha256(data).hexdigest(),sourceHashKind='downloaded-reference-bytes',vectorSha256=hashlib.sha256(vector).hexdigest(),filename=output.name,bytes=len(vector),width=im.width,height=im.height,onDark=False,method='service-vector-from-public-stock-identity-reference',checkedAt='2026-10-07')
        return result
    except Exception as e:
        row=dict(row);row['referenceArtworkFailure']=str(e)[:200];return row

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--compact-all',action='store_true');args=parser.parse_args()
    rows=json.loads(icons.MANIFEST.read_text());positions={r['stockCode']:i for i,r in enumerate(rows)};todo=[r for r in rows if r['status']=='missing' or args.compact_all and r['stockCode']!='005380' and r.get('method')!='service-vector-from-public-stock-identity-reference']
    print('Reference vector candidates',len(todo),flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        futures=[pool.submit(draw,row) for row in todo]
        for n,f in enumerate(concurrent.futures.as_completed(futures),1):
            row=f.result();rows[positions[row['stockCode']]]=row
            if n%100==0:print(icons.publish(rows),flush=True)
    print(icons.publish(rows),flush=True)
