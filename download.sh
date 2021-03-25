git submodule update --init

[ -f "cased_L-12_H-768_A-12.zip" ] || [ -d "cased_L-12_H-768_A-12/"  ] || wget "https://storage.googleapis.com/bert_models/2018_10_18/cased_L-12_H-768_A-12.zip"
[ -d "cased_L-12_H-768_A-12/" ] || unzip cased_L-12_H-768_A-12.zip
