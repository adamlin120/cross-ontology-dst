from argparse import ArgumentParser
from pathlib import Path

import pandas as pd


def _parse_args():
    parser = ArgumentParser()
    parser.add_argument("dir", type=Path)
    parser.add_argument("output", type=Path)
    return parser.parse_args()


def main():
    args = _parse_args()
    metric = []
    for p in args.dir.glob("metric.*.csv"):
        df = pd.read_csv(p, index_col="domain")
        config = p.stem.split(".")[1]
        df.insert(0, "config", [config] * len(df))
        metric.append(df)
    metric = pd.concat(metric)
    metric.to_csv(args.output)
    print(metric)


if __name__ == "__main__":
    main()
