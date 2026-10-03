import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cloudflare_release as pages
import release


class CloudflareReleaseTests(unittest.TestCase):
    def value(self, **changes):
        return dict(id='a'*8+'-'+ 'a'*4+'-'+ 'a'*4+'-'+ 'a'*4+'-'+ 'a'*12,
                    project_name='alfinder-web', environment='production',
                    latest_stage={'status':'success'}, url='https://abcdef.alfinder-web.pages.dev',
                    deployment_trigger={'metadata':{'commit_hash':'b'*40,'commit_dirty':False}},
                    env_vars={'PRIVATE':{'value':'must-not-persist'}}, **changes)

    def record(self):
        return {'provider':'cloudflare-pages','projectName':pages.PROJECT,'accountId':pages.ACCOUNT,
                'deployment':{'id':'current'},'backend':'exact-image-and-revision',
                'previous':{'id':'old','url':'https://old.alfinder-web.pages.dev',
                            'fileHashes':{name:'c'*64 for name in ('main.dart.js','index.html','release.json','flutter_bootstrap.js')}}}

    def test_only_exact_successful_clean_project_environment_accepted(self):
        value=self.value()
        accepted=pages.deployment(value,'production','b'*40)
        self.assertNotIn('env_vars',accepted)
        for key,bad in [('project_name','other'),('environment','preview'),('id','invalid'),('url','https://evil.example.com'),('latest_stage',{'status':'failure'}),('deployment_trigger',{'metadata':{'commit_hash':'c'*40,'commit_dirty':False}}),('deployment_trigger',{'metadata':{'commit_hash':'b'*40,'commit_dirty':True}})]:
            with self.subTest(key=key),self.assertRaises(ValueError):
                pages.deployment({**value,key:bad},'production','b'*40)

    def test_upload_binds_immutable_url_not_branch_alias_or_latest(self):
        value=self.value(); value['environment']='preview'
        with patch.object(pages,'cli',return_value='https://abcdef.alfinder-web.pages.dev\nhttps://release-preview.alfinder-web.pages.dev') as cli,patch.object(pages,'api',return_value=[value]):
            self.assertEqual(pages.upload(Path('/artifact'),'b'*40)['id'],value['id'])
            args=cli.call_args.args
            self.assertIn('release-preview-'+'b'*40,args)
            self.assertIn('--commit-dirty=false',args)
        with patch.object(pages,'cli',return_value=value['url']),patch.object(pages,'api',return_value=[value,value]),self.assertRaises(ValueError):
            pages.upload(Path('/artifact'),'b'*40)

    def test_preview_is_never_a_rollback_target(self):
        value=self.value();value['environment']='preview'
        with patch.object(pages,'api',return_value=value) as api,self.assertRaises(ValueError):
            pages.rollback({'id':value['id'],'url':value['url']})
        api.assert_called_once()

    def test_wrong_project_branch_stops_before_upload(self):
        with patch.object(pages,'api',return_value={'name':'alfinder-web','production_branch':'other'}),self.assertRaises(ValueError):
            pages.production()

    def test_auth_401_guard_and_bootstrap_checksum(self):
        manifest={'mainJsSha256':release.hashlib.sha256(b'app').hexdigest(),'files':{}}
        for name in ['index.html','release.json','flutter_bootstrap.js']:
            manifest['files']['static/'+name]=release.hashlib.sha256(name.encode()).hexdigest()
        def fetch(url,data=None):
            if url.endswith('/main.dart.js'):return b'app'
            if '/api/company/' in url:return b'{"totalListed":1}'
            if '/api/membership/' in url:raise HTTPError(url,401,'unauthenticated',{},None)
            return url.rsplit('/',1)[-1].encode()
        with patch.object(release,'fetch',side_effect=fetch):release.check_web('https://example',manifest)
        def unguarded(url,data=None):
            return b'{}' if '/api/membership/' in url else fetch(url,data)
        with patch.object(release,'fetch',side_effect=unguarded),self.assertRaises(ValueError):
            release.check_web('https://example',manifest)
        bad={**manifest,'files':{**manifest['files'],'static/flutter_bootstrap.js':'0'*64}}
        with patch.object(release,'fetch',side_effect=fetch),self.assertRaises(ValueError):
            release.check_web('https://example',bad)

    def test_provider_foreign_and_backend_changed_rollback_are_blocked(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'record.json'
            for record in [{**self.record(),'provider':'vercel'},self.record()]:
                path.write_text(json.dumps(record))
                with patch.object(release,'production',return_value={'id':'current'}),patch.object(release,'backend',return_value='changed'),patch.object(pages,'rollback') as restore,self.assertRaises(ValueError):
                    release.rollback(path)
                restore.assert_not_called()

    def test_api_credentials_are_only_in_request_header_not_errors(self):
        with patch.object(pages,'cli',return_value=json.dumps({'type':'oauth','token':'synthetic-private'})),patch.object(pages,'urlopen',side_effect=HTTPError('https://api.cloudflare.com',403,'synthetic-private',{},None)),self.assertRaises(ValueError) as error:
            pages.api()
        self.assertNotIn('synthetic-private',str(error.exception))

    def test_release_orchestration_preview_failure_blocks_production_and_records_before_mutation(self):
        import contextlib
        import io
        from unittest.mock import Mock
        commit='b'*40
        manifest={'commit':commit,'workflowRun':'5','verification':'github-actions','mainJsSha256':'c'*64}
        candidate={'conclusion':'success','status':'completed','event':'push','head_branch':'main',
                   'head_repository':{'full_name':release.REPO},'path':'.github/workflows/release.yml',
                   'head_sha':commit,'html_url':'https://github.com/run/5'}
        previous={'id':'previous','url':'https://old.alfinder-web.pages.dev','environment':'production'}
        preview={'id':'preview','url':'https://preview.alfinder-web.pages.dev','environment':'preview'}
        target={'id':'target','url':'https://target.alfinder-web.pages.dev','environment':'production'}
        def gh(path,payload=None):
            if path.startswith('actions/'):return candidate
            if path.startswith('commits/'):return {'sha':commit}
            if path=='deployments':return {'id':1}
            return {}
        def command(*args,**kwargs):
            return commit if args[:3]==('git','rev-parse','HEAD') else ''
        def prepare(source,destination):
            # Real prepare rejects nested output: verify orchestration is separate.
            self.assertNotIn(source,destination.parents)
            destination.mkdir();(destination/'main.dart.js').write_text('sealed')
        for scenario in ['backend-stale','preview-fails','production-changed','package-changed','success']:
            fail_preview=scenario=='preview-fails'
            with self.subTest(scenario=scenario),tempfile.TemporaryDirectory() as directory,contextlib.ExitStack() as stack:
                state=Path(directory)
                stack.enter_context(patch.object(release,'STATE',state))
                stack.enter_context(patch.object(release,'gh_api',side_effect=gh))
                stack.enter_context(patch.object(release,'run',side_effect=command))
                stack.enter_context(patch.object(release,'unpack'))
                stack.enter_context(patch.object(release,'verify_bundle',return_value=manifest))
                stack.enter_context(patch.object(release,'prepare',side_effect=prepare))
                stack.enter_context(patch.object(release,'backend',return_value='sha256:'+'a'*64+' '+('c'*40 if scenario=='backend-stale' else commit)))
                stack.enter_context(patch.object(release,'web_hashes',return_value={'main.dart.js':'c'*64}))
                stack.enter_context(patch.object(release,'check_hashes'))
                stack.enter_context(patch.object(release,'production',side_effect=[dict(previous),dict(target) if scenario=='production-changed' else dict(previous),dict(previous),dict(target)]))
                prepared_file=[]
                def prepare(source,destination):
                    self.assertNotIn(source,destination.parents)
                    destination.mkdir();file=destination/'main.dart.js';file.write_text('sealed');prepared_file.append(file)
                stack.enter_context(patch.object(release,'prepare',side_effect=prepare))
                def check(url,*args,**kwargs):
                    if scenario=='package-changed' and url==preview['url']:prepared_file[0].write_text('tampered')
                    if fail_preview and url==preview['url']:raise ValueError('Preview auth/SHA mismatch')
                    return 'c'*64
                stack.enter_context(patch.object(release,'check_web',side_effect=check))
                def upload(directory,sha,production_environment=False):
                    if production_environment:
                        durable=json.loads((state/'preview.json').read_text())
                        self.assertEqual(durable['status'],'production-upload-requested')
                        self.assertEqual(durable['previous']['id'],'previous')
                        self.assertIn('preparedFiles',durable)
                        return target
                    return preview
                uploader=stack.enter_context(patch.object(pages,'upload',side_effect=upload))
                stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
                if scenario!='success':
                    with self.assertRaises(ValueError):release.deploy(run_id=5)
                    self.assertEqual(uploader.call_count,0 if scenario=='backend-stale' else 1)
                    self.assertEqual(list(state.iterdir()),[])
                else:
                    release.deploy(run_id=5)
                    self.assertEqual(uploader.call_count,2)
                    durable=json.loads((state/'preview.json').read_text())
                    self.assertEqual(durable['status'],'success')
                    self.assertEqual(durable['deployment']['id'],'target')
                    self.assertEqual(durable['provider'],'cloudflare-pages')

    def test_fetch_declares_release_user_agent_and_keeps_origin_cache_headers(self):
        from unittest.mock import MagicMock
        response = MagicMock()
        response.__enter__.return_value.read.return_value = b'public'
        with patch.object(release, 'urlopen', return_value=response) as opener:
            self.assertEqual(release.fetch('https://example/main.dart.js'), b'public')
        request = opener.call_args.args[0]
        self.assertEqual(request.get_header('User-agent'), 'alfinder-release/1.0')
        self.assertEqual(request.get_header('Origin'), release.CONFIG['productionUrl'])
        self.assertEqual(request.get_header('Cache-control'), 'no-cache')

    def test_backend_revision_requires_exact_artifact_commit(self):
        commit = 'b' * 40
        image = 'sha256:' + 'a' * 64
        release.require_backend_commit(image + ' ' + commit, commit)
        for identity in [image, image + ' <no value>', image + ' ' + 'c' * 40,
                         image + ' ' + commit[:7], image + ' ' + commit + ' extra',
                         image + ' ' + commit + '\n' + image + ' ' + commit]:
            with self.subTest(identity=identity), self.assertRaises(ValueError):
                release.require_backend_commit(identity, commit)

    def test_legacy_and_unknown_outcome_records_do_not_invoke_rollback(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'record.json'
            for record in [{'deployment':{'id':'current'}},{k:v for k,v in self.record().items() if k!='deployment'}]:
                path.write_text(json.dumps(record))
                with patch.object(pages,'rollback') as restore,self.assertRaises(ValueError):release.rollback(path)
                restore.assert_not_called()

if __name__=='__main__':unittest.main()


class WebOnlyBackendTests(unittest.TestCase):
    def test_unchanged_sources_and_existing_locks_only(self):
        source, commit = 'a' * 40, 'b' * 40
        identity = 'sha256:' + 'c' * 64 + ' ' + source
        old = 'packages:\n  serverpod:\n    version: "4.0.0"\nsdks:\n'
        new = old.replace('sdks:', '  shad:\n    version: "0.99.4"\nsdks:')
        def command(*args):
            if args[:2] == ('git', 'show'):
                return old if args[2].startswith(source) else new
            return ''
        with patch.object(release, 'run', side_effect=command):
            release.require_compatible_backend(identity, commit, source)
        with patch.object(release, 'run', return_value='server changed'), self.assertRaises(ValueError):
            release.require_compatible_backend(identity, commit, source)
        with patch.object(release, 'run', side_effect=lambda *args: old if args[:2] == ('git', 'show') and args[2].startswith(source) else old.replace('4.0.0', '4.1.0') if args[:2] == ('git', 'show') else ''), self.assertRaises(ValueError):
            release.require_compatible_backend(identity, commit, source)
        with self.assertRaises(ValueError):
            release.require_compatible_backend(identity, commit, commit)
