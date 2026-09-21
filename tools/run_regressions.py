"""Run Godot suites in isolated per-suite profiles; emit compact status and logs."""
from pathlib import Path
import subprocess, os, concurrent.futures, sys, json
ROOT=Path(__file__).resolve().parents[1]
GODOT=Path(os.environ.get('GODOT',r'C:\Users\songsorosong\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'))
LOGS=ROOT/'build/logs/058'
LOGS.mkdir(parents=True,exist_ok=True)
names=sys.argv[1:] or [p.stem for p in (ROOT/'tests').glob('*tests.gd')]+['ui_smoke','heartbeat_053_simulation','clear_signal_057_simulation']
def run(name):
    env=os.environ.copy(); env['APPDATA']=str(ROOT/'build/qa-profiles'/name)
    Path(env['APPDATA']).mkdir(parents=True,exist_ok=True)
    args=[str(GODOT),'--headless','--path',str(ROOT),'--script',f'res://tests/{name}.gd']
    if name=='run_tests': args+=['--','--games=40']
    try:
        p=subprocess.run(args,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=240)
        log=p.stdout+p.stderr
        (LOGS/(name+'.log')).write_text(log,encoding='utf-8')
        # The sandbox cannot always read Windows' OS certificate store. This
        # startup diagnostic is recorded verbatim, separately from game failures.
        failures=[line for line in log.splitlines() if ('FAIL' in line or 'SCRIPT ERROR' in line or 'ERROR:' in line) and 'Failed to read the root certificate store' not in line]
        status='PASS' if p.returncode==0 and not failures and ' OK' in log else 'FAIL'
        return {'test':name,'status':status,'exit':p.returncode,'details':failures[:12]}
    except subprocess.TimeoutExpired as e:
        def decoded(value): return value.decode('utf-8',errors='replace') if isinstance(value,bytes) else (value or '')
        (LOGS/(name+'.log')).write_text(decoded(e.stdout)+decoded(e.stderr),encoding='utf-8')
        return {'test':name,'status':'TIMEOUT'}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results=[]
    for result in pool.map(run,names):
        results.append(result)
        print(json.dumps(result,ensure_ascii=False),flush=True)
(LOGS/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
sys.exit(0 if all(x['status']=='PASS' for x in results) else 1)
