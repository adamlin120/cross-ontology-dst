CKPT="./output/t5s/checkpoint-40000/"
for DATASET_VERSION in "2.1" "2.2";
do
  for setting in "original" "desc" "onto" "both";
  do
      MWOZ_GT_DIR="./datasets/MultiWOZ_${DATASET_VERSION}_${setting}/"
      config="v${DATASET_VERSION}_slots_${setting}"
      result_dir="results/${config}/"
      gen_text="${result_dir}/generated_predictions.txt"
      metric_file="${result_dir}/metric.json"
      metric_nf_file="${result_dir}/metric.nofuzzy.json"

      echo "Ground truth MultiWOZ Data at ${MWOZ_GT_DIR}"
      echo "Start testing with setting: ${setting}"

      [[ -f "${gen_text}" ]] || bash ./run_test_mwoz.sh "${CKPT}" "${config}"
      [[ -f "${result_dir}/dialogues_001.json" ]] || python clean_generated_predictions.py "${gen_text}" "${config}"
      [[ -f "${metric_file}" ]] || python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_file}" \
          --joint_acc_across_turn=true
      [[ -f "${metric_nf_file}" ]] || python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_nf_file}" \
          --joint_acc_across_turn=true \
          --use_fuzzy_match=false
  done
done