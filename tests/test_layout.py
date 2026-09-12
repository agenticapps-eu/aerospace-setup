import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('layout', ROOT / 'env/layout.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def window(i, bundle, ws='2', layout='h_tiles', title='', pid=100):
    return {'window-id': i, 'app-bundle-id': bundle, 'workspace': ws,
            'window-layout': layout, 'window-title': title, 'app-pid': pid}


class Fake:
    def __init__(self, windows, monitors=('Odyssey G93SC',)):
        self.items = windows
        self.names = list(monitors)
        self.calls = []
    def monitors(self): return self.names
    def windows(self): return [dict(w) for w in self.items]
    def run(self, *args):
        self.calls.append(args)
        if args[0] == 'move-node-to-workspace':
            next(w for w in self.items if str(w['window-id']) == args[2])['workspace'] = args[3]
        if args[0] == 'layout' and '--window-id' in args:
            next(w for w in self.items if str(w['window-id']) == args[-1])['window-layout'] = args[1]
        return ''


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
    def controller(self, api):
        return m.Controller(api, Path(self.temp.name), ROOT / 'env', ROOT / 'aerospace.toml')
    def test_profiles_fail_closed(self):
        self.assertEqual(m.profile(['Built-in Retina Display']), 'laptop')
        self.assertEqual(m.profile(['Built-in Retina Display', 'LG ULTRAWIDE']), 'desktop')
        with self.assertRaises(ValueError): m.profile([])
    def test_round_trip_preserves_existing_floats_and_routes_new_window(self):
        api = Fake([window(1,'app.zen-browser.zen'), window(2,'com.google.Chrome','6'),
                    window(3,'com.microsoft.teams2','4','floating')])
        c = self.controller(api); c.sync('monitor'); api.calls.clear()
        c.sync('monitor')
        self.assertEqual(api.calls, [('reload-config',)])
        api.names = ['Built-in Retina Display']; c.sync('monitor')
        self.assertEqual([w['workspace'] for w in api.items], ['4','7','7'])
        self.assertEqual(api.items[1]['window-layout'], 'floating')
        api.items.append(window(4,'app.zen-browser.zen'))
        c.sync('window', 4)
        self.assertEqual(api.items[3]['workspace'], '4')
        api.names = ['Odyssey G93SC']; c.sync('monitor')
        self.assertEqual(api.items[1]['window-layout'], 'h_tiles')
        self.assertEqual(api.items[2]['window-layout'], 'floating')
        self.assertNotIn('flatten-workspace-tree', [x[0] for x in api.calls])
    def test_reused_window_id_does_not_restore_another_process(self):
        api = Fake([window(1,'com.google.Chrome','6')], ['Built-in Retina Display'])
        c=self.controller(api); c.sync('monitor')
        api.items[0]['app-pid']=999; api.names=['Odyssey G93SC']; c.sync('monitor')
        self.assertEqual(api.items[0]['window-layout'],'floating')
    def test_discover_plan_includes_extra_tiles_and_multiple_windows(self):
        ws=[window(9,'other'),window(2,'io.readwise.read'),window(3,'app.zen-browser.zen'),
            window(4,'com.openai.codex'),window(5,'app.zen-browser.zen'),
            window(6,'io.raindrop.macapp'),window(7,'helper',layout='floating')]
        order,pair=m.discover_order(ws)
        self.assertEqual(order,[3,5,4,9,6,2]); self.assertEqual(pair,(6,2))
    def test_failed_move_does_not_commit_profile(self):
        api=Fake([window(1,'app.zen-browser.zen')]);c=self.controller(api);c.sync('monitor')
        def fail(*a): raise RuntimeError('CLI disconnected')
        api.run=fail;api.names=['Built-in Retina Display']
        with self.assertRaises(RuntimeError):c.sync('monitor')
        self.assertEqual(c.load()['profile'],'desktop')


class FailureTests(unittest.TestCase):
    setUp = RoutingTests.setUp
    controller = RoutingTests.controller
    def test_corrupt_state_does_not_move(self):
        api=Fake([window(1,'app.zen-browser.zen','4')])
        c=self.controller(api)
        (Path(self.temp.name)/'profile.json').write_text('{bad')
        with self.assertRaises(ValueError): c.sync('monitor')
        self.assertEqual(api.calls, [])
    def test_disabled_does_not_even_reload(self):
        api=Fake([]); c=self.controller(api)
        (Path(self.temp.name)/'disabled').touch()
        self.assertEqual(c.sync('monitor'),'disabled')
        self.assertEqual(api.calls,[])
    def test_unassigned_helper_returns_to_original_workspace(self):
        api=Fake([window(1,'com.apple.finder','3','floating')])
        c=self.controller(api);c.sync('monitor')
        api.names=['Built-in Retina Display'];c.sync('monitor')
        self.assertEqual(api.items[0]['workspace'],'7')
        api.names=['LG ULTRAWIDE'];c.sync('monitor')
        self.assertEqual(api.items[0]['workspace'],'3')
        self.assertEqual(api.items[0]['window-layout'],'floating')
    def test_same_pid_with_new_start_does_not_restore(self):
        api=Fake([window(1,'com.google.Chrome','6')],['Built-in Retina Display'])
        api.items[0]['process-start']='first-start'
        c=self.controller(api);c.sync('monitor')
        api.items[0]['process-start']='second-start'
        api.names=['LG ULTRAWIDE'];c.sync('monitor')
        self.assertEqual(api.items[0]['window-layout'],'floating')
    def test_new_permanent_pin_is_not_reversed(self):
        api=Fake([window(1,'com.google.Chrome','6')],['Built-in Retina Display'])
        c=self.controller(api);c.sync('monitor')
        pin=Path(self.temp.name)/'config.toml'
        pin.write_text("{ if = 'test %{app-bundle-id} = com.google.Chrome', run = 'layout floating' }")
        c.config=pin;api.names=['LG ULTRAWIDE'];c.sync('monitor')
        self.assertEqual(api.items[0]['window-layout'],'floating')
    def test_window_closing_during_move_is_not_floated(self):
        api=Fake([window(1,'com.google.Chrome','6')],['Built-in Retina Display'])
        original=api.run
        def close(*args):
            result=original(*args)
            if args[0]=='move-node-to-workspace':api.items=[]
            return result
        api.run=close;c=self.controller(api);c.sync('monitor')
        self.assertEqual(c.load()['floats'],{})
        self.assertFalse(any(call[0]=='layout' for call in api.calls))
    def test_silent_failed_move_is_not_success(self):
        api=Fake([window(1,'app.zen-browser.zen','4')]); c=self.controller(api)
        api.run=lambda *args:''
        with self.assertRaises(RuntimeError):c.sync('relayout')
        self.assertIsNone(c.load()['profile'])

class DiscoverFake(Fake):
    def __init__(self, windows):
        super().__init__(windows)
        self.order=[w['window-id'] for w in windows]
        self.focused=self.order[0]
    def run(self,*args):
        self.calls.append(args)
        if args[0]=='focus':
            self.focused=(self.order[int(args[2])] if args[1]=='--dfs-index' else int(args[2]))
        if args[0]=='list-windows':return str(self.focused)
        if args[0]=='swap':
            i=self.order.index(int(args[2]));self.order[i-1],self.order[i]=self.order[i],self.order[i-1]
        return ''

class DiscoverTests(unittest.TestCase):
    def test_orders_all_tiles_joins_only_reader_pair_restores_focus(self):
        api=DiscoverFake([window(9,'other'),window(2,'io.readwise.read'),window(3,'app.zen-browser.zen'),
            window(4,'com.openai.codex'),window(5,'app.zen-browser.zen'),window(6,'io.raindrop.macapp')])
        m.discover(api)
        self.assertEqual(api.order,[3,5,4,9,6,2]);self.assertEqual(api.focused,9)
        self.assertEqual([c for c in api.calls if c[0]=='join-with'],[('join-with','--window-id','2','left')])
    def test_failed_swaps_never_join(self):
        api=DiscoverFake([window(2,'io.readwise.read'),window(3,'app.zen-browser.zen'),window(6,'io.raindrop.macapp')])
        original=api.run
        api.run=lambda *a: '' if a[0]=='swap' else original(*a)
        with self.assertRaises(RuntimeError):m.discover(api)
        self.assertFalse(any(c[0]=='join-with' for c in api.calls))
        self.assertEqual(api.focused,2)

if __name__ == '__main__': unittest.main()
