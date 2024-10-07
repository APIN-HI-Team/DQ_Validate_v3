from PySide6.QtCore import QObject, QFileSystemWatcher, Signal

class FileWatcherManager(QObject):
    fileChanged = Signal(str, str)  # Signal to emit file changes (key, path)

    _instance = None  # Singleton instance

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self, *args, **kwargs):
        if FileWatcherManager._instance is not None:
            raise RuntimeError("FileWatcherManager is a singleton class and cannot be instantiated more than once.")
        super().__init__(*args, **kwargs)
        self.watchers = {}  # Dictionary to store QFileSystemWatcher instances
        self.active_watchers = set()  # Set to track active watchers

    def add_watcher(self, key, paths, callback):
        """Adds a file watcher for the given paths."""
        if key in self.watchers:
            print(f"Watcher with key '{key}' already exists.")
            return
    
        watcher = QFileSystemWatcher(paths)
        watcher.fileChanged.connect(lambda path: callback(key, path))  # Ensure the correct callback signature
        self.watchers[key] = {
            'watcher': watcher,
            'callback': callback
        }
        self.start_watcher(key)


    def start_all_watchers(self):
        for key in self.watchers.keys():
            self.start_watcher(key)

    def stop_all_watchers(self, exceptions=None):
        if exceptions is None:
            exceptions = set()

        for key in self.watchers.keys():
            if key not in exceptions:
                self.stop_watcher(key)

    def stop_watcher(self, key):
        if key in self.watchers:
            self.active_watchers.discard(key)
            self.watchers[key]['watcher'].blockSignals(True)
        else:
            print(f"Watcher with key '{key}' does not exist.")

    def start_watcher(self, key):
        if key in self.watchers:
            self.active_watchers.add(key)
            watcher_info = self.watchers[key]
            watcher_info['watcher'].blockSignals(False)
            # Trigger the callback manually for existing files
            for path in watcher_info['watcher'].files():
                watcher_info['callback'](path)
        else:
            print(f"Watcher with key '{key}' does not exist.")

    def stop_specific_watchers(self, active_watchers):
        if not isinstance(active_watchers, set):
            active_watchers = set(active_watchers)

        for key in self.watchers.keys():
            if key in active_watchers:
                self.start_watcher(key)
            else:
                self.stop_watcher(key)

    def trigger_callback(self, key, path=None):
        """Manually trigger the callback for a specific watcher."""
        if key in self.watchers:
            watcher_info = self.watchers[key]
            if path:
                watcher_info['callback'](path)
            else:
                # Trigger the callback for all watched files
                for path in watcher_info['watcher'].files():
                    watcher_info['callback'](path)
        else:
            print(f"Watcher with key '{key}' does not exist.")

    def trigger_all_callbacks(self):
        """Manually trigger callbacks for all watchers."""
        for key in self.watchers.keys():
            self.trigger_callback(key)
