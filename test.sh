export CUDA_VISIBLE_DEVICES=0
bash ./run_test_mwoz.sh ./output/t5s/checkpoint-40000/ v2.2_slots_desc
bash ./run_test_mwoz.sh ./output/t5s/checkpoint-40000/ v2.2_slots_onto
bash ./run_test_mwoz.sh ./output/t5s/checkpoint-40000/ v2.2_slots_both
