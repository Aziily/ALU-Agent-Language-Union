flow cachetools_lib:
  steps:
    - keys_group
    - caches_group


flow keys_group:
  steps:
    - hashkey
    - methodkey
    - typedkey
    - typedmethodkey


flow caches_group:
  steps:
    - fifo_cache
    - lfu_cache
    - lru_cache
    - mru_cache
    - rr_cache
    - ttl_cache


code hashkey:
  body: |
    def hashkey(*args, **kwargs):
        """Return a cache key for the specified hashable arguments."""
        pass


code methodkey:
  body: |
    def methodkey(self, *args, **kwargs):
        """Return a cache key for the specified hashable arguments."""
        pass


code typedkey:
  body: |
    def typedkey(*args, **kwargs):
        """Return a typed cache key for the specified hashable arguments."""
        pass


code typedmethodkey:
  body: |
    def typedmethodkey(self, *args, **kwargs):
        """Return a typed cache key for the specified hashable arguments."""
        pass


code fifo_cache:
  body: |
    def fifo_cache(maxsize=128, typed=False):
        """Decorator wrapping a function with a FIFO cache (first in, first out)."""
        pass


code lfu_cache:
  body: |
    def lfu_cache(maxsize=128, typed=False):
        """Decorator wrapping a function with an LFU cache (least frequently used)."""
        pass


code lru_cache:
  body: |
    def lru_cache(maxsize=128, typed=False):
        """Decorator wrapping a function with an LRU cache (least recently used)."""
        pass


code mru_cache:
  body: |
    def mru_cache(maxsize=128, typed=False):
        """Decorator wrapping a function with an MRU cache (most recently used)."""
        pass


code rr_cache:
  body: |
    def rr_cache(maxsize=128, choice=random.choice, typed=False):
        """Decorator wrapping a function with a random cache."""
        pass


code ttl_cache:
  body: |
    def ttl_cache(maxsize=128, ttl=600, timer=time.monotonic, typed=False):
        """Decorator wrapping a function with a time-to-live cache."""
        pass
