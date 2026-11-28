#!/usr/bin/env python3
"""Export redacted MQTT/Tasmota entity/device/area registry metadata."""
import argparse,json
from pathlib import Path
def data(p):return json.loads(p.read_text(encoding='utf-8')).get('data',{})
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--entities',type=Path,required=True);p.add_argument('--devices',type=Path,required=True);p.add_argument('--areas',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();dev={x.get('id'):x for x in data(a.devices).get('devices',[])};areas={x.get('id'):x.get('name') for x in data(a.areas).get('areas',[])};out=[]
 for e in data(a.entities).get('entities',[]):
  if e.get('platform') not in ('mqtt','tasmota'):continue
  d=dev.get(e.get('device_id'),{});ar=e.get('area_id') or d.get('area_id');out.append({'entity_id':e.get('entity_id'),'platform':e.get('platform'),'unique_id':e.get('unique_id'),'device_id':e.get('device_id'),'device_name':d.get('name_by_user') or d.get('name'),'manufacturer':d.get('manufacturer'),'model':d.get('model'),'area':areas.get(ar),'disabled_by':e.get('disabled_by'),'hidden_by':e.get('hidden_by')})
 a.output.write_text(json.dumps(out,ensure_ascii=False,indent=2,sort_keys=True)+'\n',encoding='utf-8');print(f'Exported entities: {len(out)}')
if __name__=='__main__':main()
