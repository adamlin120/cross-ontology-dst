from argparse import ArgumentParser
from pathlib import Path

import pandas as pd


def _parse_args():
    parser = ArgumentParser()
    parser.add_argument("--output", type=Path, default="./google_baseline_prediction/metric.csv")
    parser.add_argument("--dir", type=Path, default="./google_baseline_prediction")
    return parser.parse_args()


def main():
    args = _parse_args()
    metric = []
    for version in ["2.1", "2.2"]:
        for setting in ["original", "desc", "onto", "both"]:
            p = args.dir / version / setting / "metric.csv"
            df = pd.read_csv(p)
            df.insert(0, "Test Set", [version] * len(df))
            df.insert(1, "Setting", [setting] * len(df))
            metric.append(df)
    metric = pd.concat(metric)
    metric.to_csv(args.output, index=False)
    print(metric)

    slot_metric = []
    for version in ["2.1", "2.2"]:
        for setting in ["original", "desc", "onto", "both"]:
            p = args.dir / version / setting / "slot.csv"
            df = pd.read_csv(p)
            df.insert(0, "Test Set", [version] * len(df))
            df.insert(1, "Setting", [setting] * len(df))
            slot_metric.append(df)
    slot_metric = pd.concat(slot_metric)
    slot_metric.to_csv(args.dir / 'slot_metric.csv', index=False)
    print(slot_metric)


if __name__ == "__main__":
    main()
