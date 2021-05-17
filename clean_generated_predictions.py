import json
from argparse import ArgumentParser
from difflib import get_close_matches
from pathlib import Path

from datasets import load_dataset
from tqdm import tqdm

config2schema_path = {
    "v2.1_slots_original": "./schemas/2.1/schema.json",
    "v2.1_slots_desc": "./schemas/2.1/schema_w_match-desc.json",
    "v2.1_slots_onto": "./schemas/2.1/schema_w_match-ontology.json",
    "v2.1_slots_both": "./schemas/2.1/schema_both.json",
    "v2.2_slots_original": "./schemas/2.2/schema.json",
    "v2.2_slots_desc": "./schemas/2.2/schema_w_match-desc.json",
    "v2.2_slots_onto": "./schemas/2.2/schema_w_match-ontology.json",
    "v2.2_slots_both": "./schemas/2.2/schema_both.json",
}


def _parse_args():
    parser = ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument(
        "config",
        type=str,
        choices=[f"{version}_slots_{setting}" for version in ['v2.1', 'v2.2'] for setting in
                 ['original', 'desc', 'onto', 'both']])
    return parser.parse_args()


def main():
    args = _parse_args()
    version, _, setting = args.config.split('_')
    multiwoz_test = Path(f'./datasets/MultiWOZ_{version[1:]}_{setting}/test/')
    schema = json.load(open(config2schema_path[args.config]))
    slot_info = {slot["name"]: slot for service in schema for slot in service["slots"]}
    dataset = load_dataset("./multi_woz_v22.py", args.config, split="test")
    preds = args.file.read_text().splitlines()
    assert len(preds) == len(
        dataset
    ), f"length of predictions expected to be length of test dataset = {len(dataset)} but got {len(preds)} instead"
    test1 = json.load((multiwoz_test / "dialogues_001.json").open())
    test2 = json.load((multiwoz_test / "dialogues_002.json").open())
    test = test1 + test2
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
        fids = [
            i
            for i, frame in enumerate(
                test[index]["turns"][int(ins["turn_id"])]["frames"]
            )
            if frame["service"] == service
        ]
        if fids:
            fid = fids[0]
        else:
            test[index]["turns"][int(ins["turn_id"])]["frames"].append({
                "service": service,
                "slots": [],
                "state": {
                    "active_intent": "NONE",
                    "requested_slots": [],
                    "slot_values": {}
                }
            })
            fid = -1

        frame = test[index]["turns"][int(ins["turn_id"])]["frames"][fid]
        frame["state"]["slot_values"][ins["name"]] = [ins["pred"]]
        if not info["is_categorical"] and ins["pred"].lower() in ins["utterance"].lower():
            frame["slots"].append({"slot": ins["name"], "value": ins["pred"]})
    pred1 = test[: len(test1)]
    pred2 = test[len(test1):]
    assert len(pred1) == len(test1)
    assert len(pred2) == len(test2)
    (args.file.parent / "schema.json").write_text(json.dumps(schema, indent=2))
    (args.file.parent / "dialogues_001.json").write_text(json.dumps(pred1, indent=2))
    (args.file.parent / "dialogues_002.json").write_text(json.dumps(pred2, indent=2))


if __name__ == "__main__":
    main()
