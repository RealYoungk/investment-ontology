#!/usr/bin/env python3
"""Resume an authenticated DART research backfill. Never stores credentials.

ALFINDER_ADMIN_TOKEN must be an existing Serverpod admin bearer token.
Only localhost HTTP or HTTPS is accepted. Failed batches keep the last cursor.
"""
import argparse,json,os,pathlib,time,urllib.request,urllib.parse,urllib.error

class NoRedirect(urllib.request.HTTPRedirectHandler):
    # A deployment redirect must never receive the administrator bearer token.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--api',default='http://localhost:8080')
    p.add_argument('--kind',choices=['insiders','majorHoldings','capital','treasury'],required=True)
    p.add_argument('--checkpoint',type=pathlib.Path,required=True)
    p.add_argument('--max-batches',type=int,default=20)
    a=p.parse_args();u=urllib.parse.urlparse(a.api)
    if u.scheme!='https' and not (u.scheme=='http' and u.hostname in ('localhost','127.0.0.1')):p.error('HTTPS or localhost required')
    if u.username or u.password or u.query or u.fragment:p.error('API URL must not contain credentials, query, or fragment')
    token=os.environ.get('ALFINDER_ADMIN_TOKEN')
    if not token:p.error('Set ALFINDER_ADMIN_TOKEN to an existing administrator token')
    if a.max_batches<1 or a.max_batches>1000:p.error('max-batches must be 1..1000')
    state=json.loads(a.checkpoint.read_text()) if a.checkpoint.exists() else {'api':a.api,'kind':a.kind,'nextCursor':''}
    if state.get('api')!=a.api or state.get('kind')!=a.kind:p.error('Checkpoint belongs to another API/kind')
    opener=urllib.request.build_opener(NoRedirect())
    for _ in range(a.max_batches):
        if state.get('done'):break
        req=urllib.request.Request(a.api.rstrip('/')+'/research/collectBatch',data=json.dumps({'kind':a.kind,'afterCorpCode':state['nextCursor'],'limit':3}).encode(),headers={'Content-Type':'application/json','Authorization':'Bearer '+token})
        try:
            with opener.open(req,timeout=180) as response:
                result=json.load(response)
                if isinstance(result,str):result=json.loads(result)
        except urllib.error.HTTPError as e:raise SystemExit(f'Collection stopped: HTTP {e.code}. Existing cursor preserved.')
        except (OSError,ValueError):raise SystemExit('Collection interrupted. Existing cursor preserved; retry is safe.')
        state.update(result)
        a.checkpoint.parent.mkdir(parents=True,exist_ok=True)
        tmp=a.checkpoint.with_suffix('.tmp');tmp.write_text(json.dumps(state,ensure_ascii=False,indent=2));tmp.replace(a.checkpoint)
        print(json.dumps({k:result.get(k) for k in ['completed','nextCursor','done','failed']},ensure_ascii=False),flush=True)
        if result.get('failed'):raise SystemExit('Failed company retained for retry; collection stopped.')
        time.sleep(1)
if __name__=='__main__':main()
