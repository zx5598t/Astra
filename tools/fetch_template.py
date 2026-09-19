"""Fetch only the official Windows release template using ZIP byte ranges."""
import urllib.request,json,struct,zlib,os
from pathlib import Path
base='https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable'
with urllib.request.urlopen(base) as r:data=json.load(r)
a=next(a for a in data['assets'] if a['name']=='Godot_v4.7.2-stable_export_templates.tpz')
url=a['browser_download_url'];size=a['size']
def get(start,end):
    req=urllib.request.Request(url,headers={'Range':f'bytes={start}-{end}'})
    with urllib.request.urlopen(req) as r:
        if r.status!=206:raise RuntimeError('Range unavailable: '+str(r.status))
        b=r.read(end-start+2)
        if len(b)!=end-start+1:raise RuntimeError('Wrong range length')
        return b
tail=get(size-65536,size-1);e=tail.rfind(b'PK\x05\x06')
_,_,_,_,count,cd_size,cd_offset,_=struct.unpack_from('<4s4H2IH',tail,e)
cd=get(cd_offset,cd_offset+cd_size-1);off=0
dest=Path(os.environ['APPDATA'])/'Godot/export_templates/4.7.2.stable';dest.mkdir(parents=True,exist_ok=True)
for i in range(count):
    h=struct.unpack_from('<4s6H3I5H2I',cd,off)
    n,x,c=h[10:13];name=cd[off+46:off+46+n].decode();off+=46+n+x+c
    if name.endswith('/windows_release_x86_64.exe') or name=='windows_release_x86_64.exe':
        comp,uncomp,local=h[8],h[9],h[-1]
        lh=get(local,local+29);v=struct.unpack('<4s5H3I2H',lh)
        start=local+30+v[-2]+v[-1]
        payload=get(start,start+comp-1);raw=zlib.decompress(payload,-15) if h[4]==8 else payload
        assert len(raw)==uncomp and zlib.crc32(raw)==h[7]
        p=dest/'windows_release_x86_64.exe';p.write_bytes(raw)
        (dest/'version.txt').write_text('4.7.2.stable')
        print('Verified official template',p,len(raw),flush=True)
        break
else:raise RuntimeError('Windows template not in archive')
