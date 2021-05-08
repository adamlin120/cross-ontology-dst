python -m baseline.train_and_predict \
        --bert_ckpt_dir cased_L-12_H-768_A-12/ \
        --dstc8_data_dir dstc8-schema-guided-dialogue/ \
        --dialogues_example_dir dialogues_example/ \
        --schema_embedding_dir schema_embedding/ \
        --output_dir output/ \
        --dataset_split train \
        --run_mode train \
        --task_name dstc8_single_domain