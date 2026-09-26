"""Black-box file behavior through each real assembly executable, no GUI."""
import datetime as dt
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

exe=Path(sys.argv[1]).resolve()
def roundtrip(raw):
    with tempfile.TemporaryDirectory() as tmp:
        path=Path(tmp)/'history.json'
        path.write_text(raw,encoding='utf-8')
        subprocess.run([str(exe),'--roundtrip'],env=dict(os.environ,COPY_PASTA_HISTORY=str(path)),check=True,timeout=10)
        return json.loads(path.read_text('utf-8'))

style={'FontName':'Consolas','FontSize':13.5,'FontWeight':700,'IsItalic':True,
       'ForegroundColor':0x332211,'BackgroundColor':0xffffff}
original=[{'Text':'  café 🍝\r\n\t"\\  ','CapturedAt':'2026-09-25T12:30:00-04:00','Style':style}]
result=roundtrip(json.dumps(original,ensure_ascii=True))
assert len(result)==1 and result[0]['Text']==original[0]['Text'],result
assert result[0]['Style']==style,result
assert dt.datetime.fromisoformat(result[0]['CapturedAt'].replace('Z','+00:00')) == dt.datetime.fromisoformat(original[0]['CapturedAt'])

fractional=[{'Text':str(i),'CapturedAt':f'2026-09-25T12:30:00.{i:07}-04:00','Style':None} for i in (1,9999999,1234567)]
result=roundtrip(json.dumps(fractional))
assert [e['Text'] for e in result]==['9999999','1234567','1'],result
assert [e['CapturedAt'] for e in result]==[fractional[i]['CapturedAt'] for i in (1,2,0)],result

entries=[{'Text':f'item {i}','CapturedAt':f'2026-09-{i//24+1:02}T{i%24:02}:00:00Z','Style':None} for i in range(60)]
result=roundtrip(json.dumps(entries))
assert [e['Text'] for e in result]==[f'item {i}' for i in range(59,9,-1)],result

for malformed in ('[', '[{"Text":"a"},]', '[{"Text":"a" "Style":null}]',
                  '[{"Text":"a","Style":{"FontSize":01}}]',
                  '[{"Text":"a","Style":{"FontSize":1e}}]', '[{"Text":"\\uZZZZ"}]',
                  '[{"Text":"a"}]garbage', '[{"Text":"a",}]',
                  '[{"Text":"a","FutureField":+1}]',
                  '[{"Text":"a","FutureField":1.}]',
                  '[{"Text":"a","FutureField":tru}]',
                  '[{"Text":"bad\\q"}]', '[{"Text":"raw\nnewline"}]',
                  '[{"Text":"valid"},{"Text":123}]',
                  '[{"Text":"a","CapturedAt":123}]',
                  '[{"Text":"a","CapturedAt":"2026-02-30T12:00:00Z"}]',
                  '[{"Text":"a","CapturedAt":"2026-09-25T12:30:00+99:99"}]',
                  '[{"Text":"a","CapturedAt":"2026-09-25T12:30:00Zjunk"}]',
                  '[{"Text":"a","Style":{"FontName":[]}}]'):
    assert roundtrip(malformed)==[],malformed

unknown=[{'Text':'kept','CapturedAt':'2026-09-25T00:00:00Z','Style':None,'FutureField':{'nested':[1,2,3]}}]
assert roundtrip(json.dumps(unknown))[0]['Text']=='kept'
valid_numbers='[{"Text":"numbers","FutureField":[0,-0,1,-12,0.5,-1.25,1e3,1E-3,1e+3,true,false,null,{}]}]'
assert roundtrip(valid_numbers)[0]['Text']=='numbers'
print('PASS: UTF-8/UTF-16 escapes, all style fields, timezone offsets, sorted cap, malformed JSON, unknown fields')
