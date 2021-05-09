#!/bin/bash
RUN_NAME="${1:-tmp}"
MODEL="${2:-mrm8488/t5-base-finetuned-squadv2}"
EPOCH="${3:-20}"

export WANDB_PROJECT="T5DST"

python run_summarization.py \
    --output_dir "./output/${RUN_NAME}" \
    --run_name "${RUN_NAME}" \
    --model_name_or_path "${MODEL}" \
    --do_train \
    --do_eval \
    --do_predict \
    --evaluation_strategy "epoch" \
    --logging_steps 100 \
    --num_train_epochs "${EPOCH}" \
    --dataset_name "./schema_guided_dstc8.py" \
    --dataset_config "slots" \
    --source_prefix "question: " \
    --text_column "service+description+history" \
    --summary_column "value" \
    --per_device_train_batch_size 2 \
    --per_device_eval_batch_size 2 \
    --gradient_accumulation_steps 2 \
    --seed 13 \
    --fp16 True \
    --load_best_model_at_end \
    --push_to_hub \
    --predict_with_generate
