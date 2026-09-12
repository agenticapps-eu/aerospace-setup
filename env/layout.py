#!/usr/bin/env python3
"""Shared window routing. No app restarts and no native macOS Spaces mutations."""
import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
STATE = Path.home() / '.local/state/aerospace'


def log(message):
    STATE.mkdir(parents=True, exist_ok=True)
    path = STATE / 'layout.log'
    if path.exists() and path.stat().st_size > 1_000_000:
        path.replace(STATE / 'layout.previous.log')
    with path.open('a') as stream:
        stream.write(time.strftime('%Y-%m-%d %H:%M:%S ') + message + '\n')


def profile(names):
    if not names:
        raise ValueError('No monitors detected; leaving layout unchanged')
    return 'laptop' if all(re.search(r'built-in|color lcd|liquid retina', n, re.I) for n in names) else 'desktop'


def read_rules(path):
    rules = []
    for raw in path.read_text().splitlines():
        parts = raw.split('#', 1)[0].split(None, 2)
        if len(parts) >= 2:
            if len(parts) == 3:
                re.compile(parts[2])  # validate before moving anything
            rules.append((parts[0].lstrip('+'), parts[1], parts[2] if len(parts) == 3 else None))
    return rules


def target(w, rules):
    for bundle, ws, pattern in rules:
        if bundle in ('*', w['app-bundle-id']) and (not pattern or re.search(pattern, w['window-title'])):
            return None if ws == '-' else ws
    return None


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent, prefix='.' + path.name)
    try:
        with os.fdopen(fd, 'w') as f:
            f.write(text)
        os.replace(name, path)
    finally:
        if os.path.exists(name): os.unlink(name)


class Aero:
    def __init__(self):
        self.exe = shutil.which('aerospace') or '/opt/homebrew/bin/aerospace'
    def run(self, *args):
        # Callback context must not override explicitly selected/focused targets.
        env = {k: v for k, v in os.environ.items() if k not in ('AEROSPACE_WINDOW_ID', 'AEROSPACE_WORKSPACE')}
        p = subprocess.run([self.exe, *args], text=True, capture_output=True, timeout=10, env=env)
        if p.returncode or '[ERROR]' in p.stdout + p.stderr:
            raise RuntimeError(f'{args[0]} failed: {p.stderr or p.stdout}')
        return p.stdout.strip()
    def monitors(self):
        return [m['monitor-name'] for m in json.loads(self.run('list-monitors', '--json'))]
    def windows(self):
        windows = json.loads(self.run('list-windows', '--all', '--format',
            '%{window-id} %{workspace} %{app-bundle-id} %{app-pid} %{window-title} %{window-layout}', '--json'))
        # Process start prevents restoration after PID reuse, including across reboot.
        proc = subprocess.run(['/bin/ps', '-axo', 'pid=,lstart='], capture_output=True,
                              text=True, check=True, timeout=10)
        starts = {int(parts[0]): parts[1] for line in proc.stdout.splitlines()
                  if len(parts := line.split(None, 1)) == 2}
        for w in windows:
            w['process-start'] = starts.get(w['app-pid'], 'unknown')
        return windows


class Controller:
    def __init__(self, api, state_dir=STATE, rules_dir=HERE, config=None):
        self.api, self.state_dir, self.rules_dir = api, Path(state_dir), Path(rules_dir)
        self.config = Path(config or Path.home() / '.config/aerospace/aerospace.toml')
    def load(self):
        path = self.state_dir / 'profile.json'
        if not path.exists(): return {'version': 1, 'profile': None, 'floats': {}, 'positions': {}}
        state = json.loads(path.read_text())
        if not isinstance(state, dict) or state.get('version') != 1:
            raise ValueError('Unknown state version; leave unchanged and inspect profile.json')
        if state.get('profile') not in (None, 'desktop', 'laptop'):
            raise ValueError('Invalid profile; leaving layout unchanged')
        for field in ('floats', 'positions'):
            if not isinstance(state.get(field, {}), dict):
                raise ValueError('Invalid state; leaving layout unchanged')
            for key, entry in state.get(field, {}).items():
                if not key.isdigit() or not isinstance(entry, dict) or not isinstance(entry.get('pid'), int):
                    raise ValueError('Invalid window state; leaving layout unchanged')
                if field == 'floats' and entry.get('layout') not in ('h_tiles','v_tiles','h_accordion','v_accordion'):
                    raise ValueError('Invalid saved layout; leaving layout unchanged')
                if field == 'positions' and not isinstance(entry.get('workspace'), str):
                    raise ValueError('Invalid saved workspace; leaving layout unchanged')
        return state
    def save(self, state):
        atomic_write(self.state_dir / 'profile.json', json.dumps(state, indent=2) + '\n')
    def pinned(self, bundle):
        if not self.config.exists(): return False
        # AeroSpace accepts TOML 1.1 multiline inline tables; Python tomllib does not.
        # AeroPilot emits bundle-wide pins as single-line callbacks.
        condition = f"if = 'test %{{app-bundle-id}} = {bundle}'"
        return any(condition in line and "run = 'layout floating'" in line
                   for line in self.config.read_text().splitlines())
    def sync(self, reason='relayout', window_id=None):
        if (self.state_dir / 'disabled').exists(): return 'disabled'
        mode = profile(self.api.monitors())
        rules_file = self.rules_dir / ('layout.laptop.conf' if mode == 'laptop' else 'layout.conf')
        rules = read_rules(rules_file)
        state = self.load()
        changed = state.get('profile') != mode
        if reason == 'monitor': self.api.run('reload-config')
        if reason == 'monitor' and not changed: return mode
        windows = self.api.windows()
        live = {str(w['window-id']): w for w in windows}
        # Remove stale/reused IDs before any restoration.
        state['floats'] = {i: v for i, v in state.get('floats', {}).items()
                           if i in live and live[i]['app-pid'] == v['pid'] and live[i].get('process-start') == v.get('start') and live[i]['app-bundle-id'] == v.get('bundle')}
        state['positions'] = {i: v for i, v in state.get('positions', {}).items()
                              if i in live and live[i]['app-pid'] == v['pid'] and live[i].get('process-start') == v.get('start') and live[i]['app-bundle-id'] == v.get('bundle')}
        self.save(state)
        for w in windows:
            if window_id is not None and not changed and w['window-id'] != window_id: continue
            wid = str(w['window-id']); ws = target(w, rules)
            if mode == 'laptop' and changed and state.get('profile') == 'desktop' and wid not in state['positions']:
                state['positions'][wid] = {'pid': w['app-pid'], 'start': w.get('process-start'), 'bundle': w['app-bundle-id'], 'workspace': w['workspace']}
                self.save(state)
            if mode == 'desktop' and ws is None and wid in state['positions']:
                ws = state['positions'][wid]['workspace']
            if ws is not None and ws != w['workspace']:
                self.api.run('move-node-to-workspace', '--window-id', wid, ws)
                actual = next((v for v in self.api.windows() if str(v['window-id']) == wid), None)
                if actual is None or actual['app-pid'] != w['app-pid'] or actual.get('process-start') != w.get('process-start'):
                    state['floats'].pop(wid, None)
                    state['positions'].pop(wid, None)
                    self.save(state)
                    continue
                if actual['workspace'] != ws:
                    raise RuntimeError('Window move not confirmed: ' + wid)
                w = actual
            temporary_float = mode == 'laptop' and ws == '7'
            if temporary_float and w['window-layout'] != 'floating':
                state['floats'].setdefault(wid, {'pid': w['app-pid'], 'start': w.get('process-start'), 'bundle': w['app-bundle-id'], 'layout': w['window-layout']})
                self.save(state)  # write-ahead: interruption must not lose the original layout
                self.api.run('layout', 'floating', '--window-id', wid)
            elif not temporary_float and wid in state['floats']:
                saved = state['floats'][wid]
                if w['window-layout'] == 'floating' and not self.pinned(w['app-bundle-id']):
                    self.api.run('layout', saved['layout'], '--window-id', wid)
                del state['floats'][wid]
                self.save(state)
        # Publish only after successful routing; old profile forces retry after failures.
        if mode == 'desktop': state['positions'] = {}
        state['profile'] = mode
        self.save(state)
        return mode


def discover_order(windows):
    tiles = [w for w in windows if w['workspace'] == '2' and w['window-layout'] != 'floating']
    groups = ['app.zen-browser.zen', 'com.anthropic.claudefordesktop', 'com.openai.codex']
    ids = [w['window-id'] for b in groups for w in tiles if w['app-bundle-id'] == b]
    rain = next((w['window-id'] for w in tiles if w['app-bundle-id'] == 'io.raindrop.macapp'), None)
    reader = next((w['window-id'] for w in tiles if w['app-bundle-id'] == 'io.readwise.read'), None)
    pair = (rain, reader) if rain is not None and reader is not None else None
    ids += [w['window-id'] for w in tiles if w['window-id'] not in ids and (not pair or w['window-id'] not in pair)]
    if pair: ids += list(pair)
    return ids, pair


def tile_order(api):
    tiles = {w['window-id'] for w in api.windows() if w['workspace'] == '2' and w['window-layout'] != 'floating'}
    count = sum(w['workspace'] == '2' for w in api.windows())
    order = []
    for i in range(count):
        api.run('focus', '--dfs-index', str(i))
        wid = int(api.run('list-windows', '--focused', '--format', '%{window-id}'))
        if wid in tiles: order.append(wid)
    return order


def discover(api):
    if profile(api.monitors()) == 'laptop':
        raise ValueError('Discover is a desktop layout; laptop layout left unchanged')
    old = api.run('list-windows', '--focused', '--format', '%{window-id}')
    desired, pair = discover_order(api.windows())
    if len(desired) < 2: return
    try:
        api.run('workspace', '2')
        api.run('flatten-workspace-tree', '--workspace', '2')
        api.run('layout', '--workspace', '2', '--root', 'h_tiles')
        # Include ALL tiles. Relative moves against a filtered list miscount Codex.
        for want in reversed(desired):
            order = tile_order(api)
            if set(order) != set(desired): raise RuntimeError('Windows changed during Discover; retry explicitly')
            for _ in range(order.index(want)):
                api.run('swap', '--window-id', str(want), 'left')
        actual = tile_order(api)
        if actual != desired: raise RuntimeError('Discover order not verified; refusing to join windows')
        if pair:
            if set(actual) != {w['window-id'] for w in api.windows() if w['workspace'] == '2' and w['window-layout'] != 'floating'}:
                raise RuntimeError('Windows changed before join; aborting')
            i = actual.index(pair[1])
            if i == 0 or actual[i-1] != pair[0]: raise RuntimeError('Reader adjacency not verified')
            api.run('join-with', '--window-id', str(pair[1]), 'left')
        api.run('balance-sizes', '--workspace', '2')
    finally:
        if old and any(str(w['window-id']) == old for w in api.windows()):
            api.run('focus', '--window-id', old)


@contextlib.contextmanager
def lock():
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'layout.lock').open('w') as f:
        deadline = time.monotonic() + 20
        while True:
            try:
                fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB); break
            except BlockingIOError:
                if time.monotonic() > deadline: raise RuntimeError('Layout busy; try again')
                time.sleep(.1)
        yield


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['monitor','relayout','window','discover','mode'])
    args = parser.parse_args()
    api = Aero()
    if args.action == 'mode': print(profile(api.monitors())); return
    if (STATE / 'disabled').exists(): print('disabled'); return
    wid = None
    if args.action == 'window':
        raw = os.environ.get('AEROSPACE_WINDOW_ID', '')
        if not raw.isdigit(): raise ValueError('New-window callback is missing its window id')
        wid = int(raw)
        time.sleep(.4)  # allow remaining synchronous on-window-detected rules to finish
    with lock():
        if args.action == 'discover': discover(api)
        else:
            result = Controller(api).sync(args.action, wid)
            print(result)
            if args.action != 'window': log(args.action + ': ' + result)


if __name__ == '__main__':
    try: main()
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as exc:
        print(f'AeroSpace layout: {exc}', file=sys.stderr)
        try: log('ERROR: ' + str(exc))
        except OSError: pass
        sys.exit(1)
