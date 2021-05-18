import json
from argparse import ArgumentParser
from difflib import get_close_matches
from itertools import chain
from pathlib import Path

from tqdm import tqdm

from datasets import load_dataset


def _parse_args():
    parser = ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--sgd", type=Path, default="./sgd/")
    return parser.parse_args()


def main():
    args = _parse_args()
    schema = json.loads((args.sgd / "test" / "schema.json").read_text())
    slot_info = {slot["name"]: slot for service in schema for slot in service["slots"]}
    dataset = load_dataset("./schema_guided_dstc8.py", "slots", split="test")
    preds = args.file.read_text().splitlines()
    assert len(preds) == len(
        dataset
    ), f"length of predictions expected to be length of test dataset = {len(dataset)} but got {len(preds)} instead"
    test_files = [json.loads(path.read_text()) for path in (args.sgd / "test").glob("dialogues_*.json")]
    test = list(chain.from_iterable(test_files))
    for d in test:
        for t in d["turns"]:
            for s in t["frames"]:
                s["slots"] = []
                if "state" not in s:
                    s["state"] = {}
                s["state"]["slot_values"] = {}
                s["state"]["requested_slots"] = []
    did2idx = {d["dialogue_id"]: i for i, d in enumerate(test)}
    for ins, pred in tqdm(zip(dataset, preds), total=len(preds)):
        service = ins["name"].split("-")[0]
        if ins["name"] not in slot_info:
            continue
        info = slot_info[ins["name"]]
        if (
            info["is_categorical"]
            and pred != "none"
            and pred not in info["possible_values"]
        ):
            pred = get_close_matches(pred, info["possible_values"], n=1, cutoff=0.0)[0]
        ins["pred"] = pred
        if pred == "none":
            continue
        index = did2idx[ins["dialogue_id"]]
        turn_id = ins["history"].count("SYSTEM: ") * 2
        fid = -1
        for i, frame in enumerate(test[index]["turns"][turn_id]["frames"]):
            if frame["service"] == service:
                fid = i
                break
        if fid == -1:
            test[index]["turns"][turn_id]["frames"].append(
                {
                    "service": service,
                    "slots": [],
                    "state": {
                        "active_intent": "NONE",
                        "requested_slots": [],
                        "slot_values": {},
                    },
                }
            )

        frame = test[index]["turns"][turn_id]["frames"][fid]
        frame["state"]["slot_values"][ins["name"]] = [ins["pred"]]
        if (
            not info["is_categorical"]
            and ins["pred"].lower() in ins["utterance"].lower()
        ):
            frame["slots"].append({"slot": ins["name"], "value": ins["pred"]})
    pred_files = []
    for i, file_size in enumerate(map(len, test_files)):
        pred_files.append(test[:file_size])
        test = test[file_size:]
    assert not test, test

    args.output_dir.mkdir(exist_ok=True, parents=True)
    (args.output_dir / "schema.json").write_text(json.dumps(schema, indent=2))
    for i, (p, t) in enumerate(zip(pred_files, test_files)):
        (args.output_dir / f"dialogues_{i:03d}.json").write_text(json.dumps(p, indent=2))


if __name__ == "__main__":
    main()
