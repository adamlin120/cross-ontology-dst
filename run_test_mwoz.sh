#!/bin/bash
MODEL="${1:-./output/t5s/checkpoint-40000/}"
DATA_CONFIG="${2:-v2.2_slots_original}"

export WANDB_PROJECT="T5DST"

python run_summarization.py \
    --output_dir "results/${DATA_CONFIG}" \
    --model_name_or_path "${MODEL}" \
    --do_predict \
    --dataset_name "./multi_woz_v22.py" \
    --dataset_config "${DATA_CONFIG}" \
    --source_prefix "question: " \
    --text_column "service+description+history" \
    --summary_column "value" \
    --per_device_eval_batch_size 32 \
    --val_max_target_length 20 \
    --seed 13 \
    --fp16 True \
    --predict_with_generate
