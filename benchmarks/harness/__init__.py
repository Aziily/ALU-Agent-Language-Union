"""Adapters wrapping external benchmarks (Commit0, SWE-bench, ...).

Each adapter exposes the same minimal interface:

    list_projects()   -> Iterable[ProjectRef]
    load_skeleton(p)  -> SkeletonRepo     # 起始 repo (空函数 + spec)
    run_tests(p, py)  -> TestResult       # 跑 pytest 并返回详细结果
"""
