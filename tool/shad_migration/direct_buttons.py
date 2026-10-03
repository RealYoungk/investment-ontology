"""One-off migration of the retired service button API to shad's direct API."""
from pathlib import Path
import re
ROOT=Path('investment_ontology_serverpod_flutter')

def split(s):
    result=[];start=0;stack=[];quote=None;escape=False;i=0
    while i<len(s):
        c=s[i]
        if quote:
            if escape:escape=False
            elif c=='\\':escape=True
            elif c==quote:quote=None
        elif c in "'\"":quote=c
        elif c in '([{':stack.append(c)
        elif c in ')]}':
            if stack:stack.pop()
        elif c==',' and not stack:result.append(s[start:i]);start=i+1
        i+=1
    result.append(s[start:]);return result

def end_at(s,start):
    depth=1;quote=None;escape=False;i=start
    while i<len(s):
        c=s[i]
        if quote:
            if escape:escape=False
            elif c=='\\':escape=True
            elif c==quote:quote=None
        elif c in "'\"":quote=c
        elif c=='(':depth+=1
        elif c==')':
            depth-=1
            if not depth:return i
        i+=1
    raise ValueError('Unclosed expression')

count=0
for p in list((ROOT/'lib').rglob('*.dart'))+list((ROOT/'test').rglob('*.dart')):
    if p.name=='app_button.dart':continue
    s=p.read_text();old=s
    matches=list(re.finditer(r'\b(AppButton|AppIconButton)\s*\(',s))
    for m in reversed(matches):
        end=end_at(s,m.end());fields={}
        for part in split(s[m.end():end]):
            part=part.strip()
            if not part:continue
            k,sep,v=part.partition(':')
            if not sep:raise ValueError(f'{p}: {part}')
            fields[k.strip()]=v.strip()
        out=[]
        for k in ['key','onPressed']:
            if k in fields:out.append(f'{k}: {fields[k]}')
        callback=fields.get('onPressed','null')
        if callback=='null':out.append('enabled: false')
        elif 'null' in callback or ('=>' not in callback and not callback.endswith('}')):out.append(f'enabled: ({callback}) != null')
        if m.group(1)=='AppButton':
            variant=fields.get('variant','ShadButtonVariant.outline')
            out.append(f'variant: {variant}')
            compact=fields.get('compact','false')
            if compact!='false':out.append('size: ShadButtonSize.sm' if compact=='true' else f'size: ({compact}) ? ShadButtonSize.sm : ShadButtonSize.regular')
            if 'tone' in fields:out.append(f"foregroundColor: {fields['tone']}")
            if 'icon' in fields:out.append(f"leading: Icon({fields['icon']}, size: 16)")
            out.append(f"child: Text({fields['label']})")
            new='ShadButton.raw('+',\n'.join(out)+')'
        else:
            out.append(f"icon: Icon({fields['icon']}, size: 16)")
            new='ShadIconButton.outline('+',\n'.join(out)+')'
            if 'tooltip' in fields:new=f"ShadTooltip(builder: (_) => Text({fields['tooltip']}), child: {new})"
        s=s[:m.start()]+new+s[end+1:];count+=1
    s=s.replace('AppButtonVariant.primary','ShadButtonVariant.primary').replace('AppButtonVariant.secondary','ShadButtonVariant.outline').replace('AppButtonVariant.link','ShadButtonVariant.link')
    s=re.sub(r'\bAppButton\b','ShadButton',s)
    s=re.sub(r"import '[^']*components/app_button.dart';", "import 'package:shad/shad.dart';",s)
    if s!=old:
        if 'Shad' in s and "import 'package:shad/shad.dart';" not in s:s="import 'package:shad/shad.dart';\n"+s
        p.write_text(s)
print(f'Migrated {count} button constructors')
