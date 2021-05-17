for DATASET_VERSION in "2.1" "2.2";
do
  for setting in "original" "desc" "onto" "both";
  do
    python -c "import datasets;datasets.load_dataset('./multi_woz_v22.py', 'v${DATASET_VERSION}_slots_${setting}')" &
  done
done