set -e

CKPT="${1:-./output/t5s/checkpoint-40000/}"

echo "SGD Test"
SGD_GT_DIR="./sgd/"
gen_text="${CKPT}/generated_predictions.txt"
result_dir="${CKPT}/sgd/test/"
metric_file="${result_dir}/metric.json"

[[ -f "${gen_text}" ]] ||
bash ./run_test.sh "${CKPT}"

[[ -f "${result_dir}/dialogues_001.json" ]] ||
python clean_sgd_generated_predictions.py "${gen_text}" "${result_dir}"

echo "Ground truth SGD Data at ${SGD_GT_DIR}"
[[ -f "${metric_file}" ]] ||
python evaluate.py \
    --dstc8_data_dir "${SGD_GT_DIR}" \
    --prediction_dir "${result_dir}" \
    --eval_set test \
    --output_metric_file "${metric_file}"


echo "T5DST MultiWOZ Test"

T5_DIR="./results/"

for DATASET_VERSION in "2.1" "2.2";
do
  for setting in "original" "desc" "onto" "both";
  do
      MWOZ_GT_DIR="./datasets/MultiWOZ_${DATASET_VERSION}_${setting}/"
      config="v${DATASET_VERSION}_slots_${setting}"
      result_dir="${T5_DIR}/${config}/"
      gen_text="${result_dir}/generated_predictions.txt"
      metric_file="${result_dir}/metric.csv"
      metric_df_file="${result_dir}/metric.default.json"
      metric_nf_file="${result_dir}/metric.nofuzzy.json"
      metric_nc_file="${result_dir}/metric.nocross.json"

      echo "Ground truth MultiWOZ Data at ${MWOZ_GT_DIR}"
      echo "Start testing with setting: ${setting}"

      [[ -f "${gen_text}" ]] ||
      bash ./run_test_mwoz.sh "${CKPT}" "${config}"

      [[ -f "${result_dir}/dialogues_001.json" ]] ||
      python clean_generated_predictions.py "${gen_text}" "${config}"

#      [[ -f "${metric_df_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_df_file}" \
          --joint_acc_across_turn=true

#      [[ -f "${metric_nc_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_nc_file}" \
          --use_fuzzy_match=false

      [[ -f "${metric_nf_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_nf_file}" \
          --joint_acc_across_turn=true \
          --use_fuzzy_match=false

      [[ -f "${metric_file}" ]] ||
      python combine_metric.py "${result_dir}" "${metric_file}"
  done
done

python combine_all_metric.py --output "${T5_DIR}/metric.csv" --dir "${T5_DIR}"


echo "Google Baseline MultiWOZ Test"

GBL_DIR="./google_baseline_prediction/"

for DATASET_VERSION in "2.1" "2.2";
do
  for setting in "original" "desc" "onto" "both";
  do
      MWOZ_GT_DIR="./datasets/MultiWOZ_${DATASET_VERSION}_${setting}/"
      result_dir="${GBL_DIR}/${DATASET_VERSION}/${setting}/"
      metric_file="${result_dir}/metric.csv"
      metric_df_file="${result_dir}/metric.default.json"
      metric_nf_file="${result_dir}/metric.nofuzzy.json"
      metric_nc_file="${result_dir}/metric.nocross.json"

      echo "Ground truth MultiWOZ Data at ${MWOZ_GT_DIR}"
      echo "Start testing with setting: ${setting}"

      [[ -f "${metric_df_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_df_file}" \
          --joint_acc_across_turn=true

      [[ -f "${metric_nc_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_nc_file}" \
          --use_fuzzy_match=false

      [[ -f "${metric_nf_file}" ]] ||
      python evaluate.py \
          --dstc8_data_dir "${MWOZ_GT_DIR}" \
          --prediction_dir "${result_dir}" \
          --eval_set test \
          --output_metric_file "${metric_nf_file}" \
          --joint_acc_across_turn=true \
          --use_fuzzy_match=false

      [[ -f "${metric_file}" ]] ||
      python combine_metric.py "${result_dir}" "${metric_file}"
  done
done

python combine_gbl_metric.py --output "${GBL_DIR}/metric.csv" --dir "${GBL_DIR}"
