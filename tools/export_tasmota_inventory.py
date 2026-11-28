#!/usr/bin/env python3
"""Generate redacted Tasmota Markdown/CSV from offline discovery and response captures."""
import argparse,csv,json
from pathlib import Path
ALLOWED=('dn','fn','hn','mac','md','t','ft','sw','rl')
def lines(p):
 for x in p.read_text(encoding='utf-8').splitlines():
  t,s,v=x.partition(' ')
  if s:
   try:v=json.loads(v)
   except json.JSONDecodeError:pass
   yield t,v
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--discovery',type=Path,required=True);p.add_argument('--responses',type=Path,required=True);p.add_argument('--output-md',type=Path,required=True);p.add_argument('--output-csv',type=Path,required=True);a=p.parse_args();d={}
 for t,v in lines(a.discovery):
  q=t.split('/')
  if len(q)==4 and q[:2]==['tasmota','discovery']:
   e=d.setdefault(q[2],{'types':set(),'cfg':{},'resp':set()});e['types'].add(q[3])
   if q[3]=='config' and isinstance(v,dict):e['cfg'].update({k:v[k] for k in ALLOWED if k in v})
 by={str(e['cfg'].get('t')):e for e in d.values() if e['cfg'].get('t')}
 for t,v in lines(a.responses):
  q=t.split('/')
  if len(q)>=3 and q[1] in ('stat','tele'):
   e=by.setdefault(q[0],{'types':set(),'cfg':{'t':q[0],'dn':q[0]},'resp':set()});e['resp'].add(q[1]+'/'+('/'.join(q[2:])))
 rows=[]
 for ident,e in d.items():
  c=e['cfg'];topic=str(c.get('t',''));model=str(c.get('md',''));r=c.get('rl',[]);rc=sum(isinstance(x,int) and x>0 for x in r) if isinstance(r,list) else 0;fn=c.get('fn',[]);friendly=next((str(x) for x in fn if x),'') if isinstance(fn,list) else str(fn or '')
  cat='Light controller' if any(x in model.lower() for x in ('rgb','magic','arilux')) else 'Plug / power' if any(x in model.lower() for x in ('gosund','swa11','maxcio')) else 'Relay / switch'
  cmds=[f'{topic}/cmnd/POWER']+[f'{topic}/cmnd/POWER{i}' for i in range(2,max(rc,1)+1)]
  rows.append({'category':cat,'device_name':str(c.get('dn') or topic or ident),'friendly_name':friendly,'hostname':str(c.get('hn','')),'mac':str(c.get('mac') or ident),'model':model,'firmware':str(c.get('sw','')),'mqtt_topic':topic,'fulltopic':str(c.get('ft','')),'relay_count':str(rc),'observed_response_types':'; '.join(sorted(e['resp'])),'command_topics':'; '.join(cmds),'room':'unknown','function':'unknown','migration_owner':'production','ha_test_status':'inventory only','review_notes':''})
 rows.sort(key=lambda x:(x['category'],x['device_name']))
 with a.output_csv.open('w',encoding='utf-8',newline='') as h:w=csv.DictWriter(h,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
 m=['# Tasmota MQTT inventory','',f'Tasmota devices: **{len(rows)}**','','> Offline-generated. Raw captures stay outside Git. All devices remain production-owned and inventory-only.','']
 for r in rows:m += [f"## {r['device_name']}",'',f"- Model/firmware: {r['model']} / {r['firmware']}",f"- MAC: `{r['mac']}`",f"- MQTT topic: `{r['mqtt_topic']}`",f"- FullTopic: `{r['fulltopic']}`",f"- Observed responses: `{r['observed_response_types'] or 'Discovery/LWT only'}`",f"- Command topics (documented, not used): `{r['command_topics']}`",'- Room: unknown','- Function: unknown','- Migration owner: production','- ha-test status: inventory only','- Review notes:','']
 a.output_md.write_text('\n'.join(m),encoding='utf-8',newline='\n');print(f'Tasmota devices: {len(rows)}')
if __name__=='__main__':main()
